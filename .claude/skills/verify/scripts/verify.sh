#!/usr/bin/env bash
# VerbEndings verification wrapper. See ../SKILL.md for the workflow.
#   verify.sh doctor                     read-only health check
#   verify.sh prepare                    import the project once (headless editor)
#   verify.sh run <steps> [--run-id ID] [--timeout SECONDS]
#   verify.sh cleanup <run-id>           stop that run's Godot and drop its data dir
set -euo pipefail

SKILL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
REPO=$(git -C "$SKILL_DIR" rev-parse --show-toplevel)
GODOT=${GODOT:-godot4.3}
ARTIFACTS=${VERIFY_ARTIFACTS:-/tmp/verbendings-verify}
ERROR_PATTERN='(^|[[:space:]])(SCRIPT ERROR|ERROR:|Parse Error)'

die() { echo "verify: $*" >&2; exit 1; }

display_args() {
  if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    local sock
    sock=$(find "/run/user/$(id -u)" -maxdepth 1 -name 'wayland-*' ! -name '*.lock' -printf '%f\n' 2>/dev/null | head -1)
    [[ -n "$sock" ]] && export WAYLAND_DISPLAY=$sock XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
  fi
  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then echo "--display-driver wayland"
  elif [[ -n "${DISPLAY:-}" ]]; then echo "--display-driver x11"
  else return 1; fi
}

untracked_imports() {
  git -C "$REPO" ls-files --others --exclude-standard -- '*.import' | sort
}

cmd_doctor() {
  local ok=1
  check() { if eval "$2" >/dev/null 2>&1; then echo "ok    $1"; else echo "FAIL  $1${3:+ — $3}"; ok=0; fi; }
  local version
  version=$("$GODOT" --version 2>/dev/null || true)
  check "Godot 4.3 at '$GODOT' ($version)" '[[ "$version" == 4.3.stable* ]]' "install Godot 4.3-stable or set GODOT="
  check "git-lfs available" 'git -C "$REPO" lfs version' "install git-lfs, then: git lfs pull --exclude=\"docs/art/**,assets/source/**\""
  check "runtime LFS objects are real files, not pointers" \
    '! git -C "$REPO" ls-files -z -- assets resources scenes | xargs -0 grep -l --no-messages -m1 "^version https://git-lfs" | grep -v "^assets/source/" | grep -q .' \
    "git lfs pull --exclude=\"docs/art/**,assets/source/**\""
  check "import cache present (.godot/imported)" '[[ -d "$REPO/.godot/imported" ]]' "verify.sh prepare"
  check "graphical display reachable" 'display_args' "no Wayland/X11 session; visual drives are BLOCKED"
  local live=""
  for pidfile in "$ARTIFACTS"/*/godot.pid; do
    [[ -f "$pidfile" ]] && kill -0 -- "-$(cat "$pidfile")" 2>/dev/null && live+=" $(basename "$(dirname "$pidfile")")"
  done
  check "no live verification instance" '[[ -z "$live" ]]' "still running:$live (verify.sh cleanup <run-id>)"
  if ss -Hlun 'sport = :28714' 2>/dev/null | grep -q .; then
    echo "note  UDP 28714 (default session port) is in use; host/join drives must type another port"
  fi
  [[ $ok == 1 ]] && echo "doctor: PASS" || { echo "doctor: FAIL"; return 1; }
}

cmd_prepare() {
  local before log
  before=$(untracked_imports)
  log=$(mktemp)
  "$GODOT" --headless --editor --path "$REPO" --quit >"$log" 2>&1 || true
  comm -13 <(echo "$before") <(untracked_imports) | (cd "$REPO" && xargs -r -d '\n' rm -f --)
  if grep -Eiq "$ERROR_PATTERN" "$log"; then
    grep -Ei "$ERROR_PATTERN" "$log" | head -20 >&2
    die "import reported errors (full log: $log)"
  fi
  rm -f "$log"
  echo "prepare: import cache ready"
}

cmd_run() {
  local steps="" run_id="" timeout=300
  while [[ $# -gt 0 ]]; do
    case $1 in
      --run-id) run_id=$2; shift 2 ;;
      --timeout) timeout=$2; shift 2 ;;
      *) steps=$1; shift ;;
    esac
  done
  [[ -f "$steps" ]] || die "steps file not found: $steps"
  steps=$(realpath "$steps")
  run_id=${run_id:-$(basename "$steps" .steps)-$(date +%Y%m%d-%H%M%S)}
  local dir="$ARTIFACTS/$run_id"
  [[ -e "$dir" ]] && die "run directory already exists: $dir"
  mkdir -p "$dir/evidence" "$dir/data"
  local display
  display=$(display_args) || die "no graphical display; a real renderer is required"
  echo "run: $run_id  evidence: $dir/evidence"
  local status=0
  # shellcheck disable=SC2086
  # setsid gives the run its own process group (pgid = recorded pid), so cleanup
  # can signal timeout and Godot together without touching anything else.
  XDG_DATA_HOME="$dir/data" setsid timeout --signal=INT --kill-after=5s "$timeout" \
    "$GODOT" $display --path "$REPO" --script "$SKILL_DIR/scripts/drive.gd" \
    -- --steps "$steps" --out "$dir/evidence" >"$dir/evidence/godot.log" 2>&1 &
  echo $! >"$dir/godot.pid"
  wait $! || status=$?
  rm -f "$dir/godot.pid"
  local verdict=PASS
  [[ $status -ne 0 ]] && verdict=FAIL
  if grep -Eiq "$ERROR_PATTERN" "$dir/evidence/godot.log"; then
    verdict=FAIL
    echo "engine errors:" >&2
    grep -Ei "$ERROR_PATTERN" "$dir/evidence/godot.log" | head -20 >&2
  fi
  grep '^\[verify\]' "$dir/evidence/godot.log" | tail -5
  echo "exit=$status verdict=$verdict evidence=$dir/evidence"
  cmd_cleanup "$run_id" >/dev/null
  [[ $verdict == PASS ]]
}

cmd_cleanup() {
  local run_id=${1:?run-id required}
  local dir="$ARTIFACTS/$run_id"
  [[ -d "$dir" ]] || die "no such run: $dir"
  if [[ -f "$dir/godot.pid" ]]; then
    local pid
    pid=$(cat "$dir/godot.pid")
    if kill -0 -- "-$pid" 2>/dev/null; then
      kill -INT -- "-$pid" 2>/dev/null || true
      for _ in 1 2 3 4 5 6; do kill -0 -- "-$pid" 2>/dev/null || break; sleep 0.5; done
      kill -KILL -- "-$pid" 2>/dev/null || true
    fi
    rm -f "$dir/godot.pid"
  fi
  rm -rf "$dir/data"
  echo "cleanup: $run_id stopped; evidence kept at $dir/evidence"
}

case ${1:-} in
  doctor) shift; cmd_doctor "$@" ;;
  prepare) shift; cmd_prepare "$@" ;;
  run) shift; cmd_run "$@" ;;
  cleanup) shift; cmd_cleanup "$@" ;;
  *) sed -n '2,6p' "$0"; exit 2 ;;
esac

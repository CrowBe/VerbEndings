#!/usr/bin/env python3
"""Run a real two-process ENet Trial and compare authoritative state."""

from __future__ import annotations

import argparse
import json
import os
import socket
import subprocess
import sys
import time


def _free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
        probe.bind(("127.0.0.1", 0))
        return int(probe.getsockname()[1])


def _command(godot: str, role: str, port: int, disconnect: bool) -> list[str]:
    command = [
        godot,
        "--headless",
        "--path",
        ".",
        "tests/TestNetworkSession.tscn",
        "--",
        f"--{role}",
        f"--port={port}",
    ]
    if disconnect:
        command.append("--disconnect")
    return command


def _finish(process: subprocess.Popen[str], timeout: float) -> tuple[int, str]:
    try:
        output, _ = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        process.kill()
        output, _ = process.communicate()
        return 124, output
    return process.returncode, output


def _digest(output: str, marker: str) -> dict[str, object] | None:
    for line in output.splitlines():
        if line.startswith(marker + " "):
            return json.loads(line.removeprefix(marker + " "))
    return None


def _run_scenario(godot: str, timeout_seconds: float, disconnect: bool) -> bool:
    port = _free_port()
    environment = os.environ.copy()
    server = subprocess.Popen(
        _command(godot, "server", port, disconnect),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        env=environment,
    )
    time.sleep(0.4)
    client = subprocess.Popen(
        _command(godot, "client", port, disconnect),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        env=environment,
    )
    client_status, client_output = _finish(client, timeout_seconds)
    server_status, server_output = _finish(server, timeout_seconds)
    print(server_output, end="")
    print(client_output, end="")
    if server_status != 0 or client_status != 0:
        print(
            f"network peers failed: server={server_status}, client={client_status}",
            file=sys.stderr,
        )
        return False
    prefix = "NETWORK_DISCONNECT" if disconnect else "NETWORK_SCENARIO"
    server_digest = _digest(server_output, f"{prefix}_SERVER")
    if disconnect:
        if server_digest is None or server_digest.get("phase") != 10:
            print("host did not complete after the client disconnected", file=sys.stderr)
            return False
        return True
    client_digest = _digest(client_output, "NETWORK_SCENARIO_CLIENT")
    if server_digest is None or client_digest is None:
        print("network peer success markers were missing", file=sys.stderr)
        return False
    if server_digest != client_digest:
        print("host and client authoritative state diverged", file=sys.stderr)
        print(json.dumps({"server": server_digest, "client": client_digest}, indent=2))
        return False
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot4.3")
    parser.add_argument("--timeout-seconds", type=float, default=20.0)
    args = parser.parse_args()
    if not _run_scenario(args.godot, args.timeout_seconds, False):
        return 1
    if not _run_scenario(args.godot, args.timeout_seconds, True):
        return 1
    print("Network session tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

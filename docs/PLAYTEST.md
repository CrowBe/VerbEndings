# External Playtest

VerbEndings provides a Linux x86_64 desktop playtest build. It is a greybox
gameplay build for completing one canonical three-Round Trial locally or with
an ENet host and client. No Godot editor or console is required.

## Install And Launch

1. Download and extract the `VerbEndings-linux-x86_64` archive into a new
   folder. Keep `VerbEndings.x86_64` and `VerbEndings.pck` together.
2. If the executable bit was not retained by the archive tool, run
   `chmod +x VerbEndings.x86_64` once.
3. Launch `VerbEndings.x86_64` from the desktop or a file manager.

The bottom-right diagnostics strip shows the build identifier and Trial seed.
Press F8 at any time to view the bounded local session summary.

## Controls

- WASD: move and steer during a Drop;
- Space: jump, or Release from the Dispensing Line during Laboratory Entry;
- left mouse: create a basic Impact;
- right mouse: Express the Subject's Verb;
- Escape: release the captured mouse;
- F5: start the configured local quick start;
- F6: restart a local Trial with the same seed;
- F7: restart a local Trial with the next seed; and
- F8: show or hide session diagnostics.

Close the application window to exit.

## Start A Trial

`LOCAL TRIAL` creates the configured local roster on one computer. One Subject
accepts input; additional Subjects are stationary participants for inspecting
Pair and Self-Chain behaviour.

For a multiplayer Trial:

1. One tester chooses `HOST SESSION` and gives the other tester the host
   computer's local network address and displayed port. The default port is
   `28714`.
2. The other tester enters that address and port, then chooses `JOIN SESSION`.
3. Each tester claims a unique Verb. The host chooses `START TRIAL` after every
   connected Subject has claimed one.

The host and client must be able to exchange UDP traffic on the selected port.
The supported playtest setup is a direct connection, normally on the same
local network; the build does not provide matchmaking or internet traversal.

## Expected Trial Flow

A Trial starts with one Verb Selection. Every Round then presents:

1. Pair Draft;
2. Experiment Brief;
3. Laboratory Entry, including independent Release, Drop and Landing;
4. the scored Experiment;
5. Recall;
6. Result Announcement; and
7. an optional Thematic Moment when authored.

The Trial contains exactly three Rounds. After Round Three, the Subject with
the sole highest Trial Score wins. A tie for First Place starts the Collapse;
the last remaining Subject is the Trial Winner.

The in-Experiment HUD shows the Objective, remaining time, Stability, Verb
Expression cooldown and individual Round Score. Result Announcements show
Round Scores and Trial Ranking. Do not rely on terminal or console output.

## Session Summary And Defect Reports

Press F8 and choose `COPY SUMMARY` after a run. The same JSON summary is stored
as `latest_session_summary.json` in the Godot user-data folder displayed in
the diagnostics view. It contains only:

- build identifier and Trial seed;
- revealed Protocol order;
- bounded lifecycle transitions;
- bounded Subject disconnect events; and
- final result, when the Trial completes.

The summary contains no player names, network addresses, credentials,
timestamps or machine-specific paths. Attach the copied JSON to a defect report
with:

- the action being attempted;
- what happened and what was expected;
- whether the issue occurred for the host, client or local Trial;
- the Round and lifecycle phase visible on screen; and
- a screenshot or short recording when the presentation is relevant.

## Smoke Checklist

- Launch: the main menu appears and its diagnostics strip shows a build and
  seed.
- Trial: complete Verb Selection, all three Pair Drafts, Experiments, Recalls
  and Result Announcements, then observe a Trial Winner or Collapse winner.
- Multiplayer: confirm host and client show the same roster, Verbs, Pairs,
  Stability, scores and final result.
- Diagnostics: press F8, copy the summary and confirm it identifies the build,
  seed, Protocol order and final result.
- Restart: press F6 to repeat the same seed, then F7 to start the next seed.
- Exit: return to the main menu where practical, close the window, and confirm
  no process remains running.

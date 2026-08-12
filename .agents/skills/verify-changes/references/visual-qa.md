# Godot visual QA

Use this workflow for rendered UI, spatial layout, camera, lighting, animation, timing, or controls. Test the running Godot application, not a browser approximation or an image-generation mock-up.

## Establish the visual contract

Read the issue acceptance criteria and the current product rules that apply to the changed experience. Relevant sources commonly include `CONTEXT.md`, `docs/WORLD_DESIGN.md`, scene tests, and resource defaults.

Translate qualitative requirements into observations and measurements before launching the application. Examples include:

- required choices are inside the viewport and visually separated
- apparatus is readable before a timed release
- subjects have enough travel time and reachable distance to make the intended choice
- camera motion remains within its defined timing and obstruction behaviour
- every route remains usable at representative roster sizes

Basic primitives are acceptable only when their hierarchy, spacing, silhouette, and interaction meaning remain coherent.

## Launch a real renderer

Use Godot 4.3 with a real display driver. Headless Godot uses a dummy renderer and cannot establish visual quality.

On Linux, inspect the current environment before choosing X11 or Wayland. Fedora Workstation commonly exposes the active display at `/run/user/<uid>/wayland-*` even when the agent process does not inherit `WAYLAND_DISPLAY`. Use the discovered values rather than assuming a display name. A representative launch is:

```bash
XDG_RUNTIME_DIR=/run/user/<uid> \
WAYLAND_DISPLAY=<discovered-socket-name> \
godot4.3 --display-driver wayland --rendering-method gl_compatibility \
  --fixed-fps 30 --path <repository> --script <temporary-probe.gd>
```

Use the environment's GUI approval mechanism when required. If no graphical session is reachable, return `BLOCKED` for visually material acceptance and explain how a person can run the same probe; do not convert a headless result into a visual pass.

## Build a deterministic probe

Prefer an existing repository harness. Otherwise create a temporary GDScript or scene under a fresh `/tmp` directory. Keep it self-terminating and ensure it cannot alter tracked resources or the user's saved configuration.

The probe must:

1. Select explicit protocols, seeds, roster sizes, and configuration values.
2. Drive input through supported gameplay seams rather than teleporting internal nodes unless measuring a specific boundary.
3. Capture frames before, during, and after the changed transition.
4. Record structured JSON or plain-text measurements beside the PNGs.
5. Close the application and leave the repository unchanged.

For shared layout or lifecycle code, cover each affected protocol plus representative minimum, typical, and maximum supported roster sizes. Include odd and even rosters when symmetry or route allocation could differ. Read supported limits from current project configuration rather than hard-coding them in the skill.

## Collect objective evidence

Measure what the acceptance criteria depend on. Use the smallest useful set from these categories:

- Project important world positions through the active camera and record whether their screen coordinates and useful footprint fall inside the viewport.
- Ray-cast from the camera to important targets and record the occluding collider and responsible node path.
- Record camera pose, field of view, spring-arm length, clipping, and transition duration.
- Record phase timings, release timing, airtime, travel distance, and landing outcome.
- Simulate sustained steering from every occupied start position in at least eight horizontal directions to estimate a reachable envelope.
- Record pairwise screen separation for choices and routes whose visual identity must be distinct.

Use geometric and physics assertions for portability. Do not rely on pixel-perfect golden comparisons across renderers.

## Inspect the captures

Open every representative capture with the available image-inspection tool at original detail. Check:

- composition and visual hierarchy
- occlusion by decorative or non-interactable geometry
- whether options look like options before input is required
- camera clipping, jumps, or uncomfortable motion
- correspondence between the screenshot and recorded screen-space measurements

Automated measurements do not replace judgement about comfort or coherence. Report those judgements as human review items while still failing objective contradictions such as an off-screen or fully occluded required target.

## Report and clean up

Report the scenario matrix, exact launch command, deterministic inputs, measurements, and absolute paths to screenshots and structured evidence. Keep artefacts under `/tmp` unless the user explicitly requests committed fixtures.

Terminate probe processes and compare the repository worktree with its initial state. Remove only transient outputs created by the probe.

# FLUX Intro Generation Evidence

## Role

This directory retains a FLUX-generated VerbEndings intro source and deterministic review evidence. It is Context Reference rather than a runtime asset. The directory is excluded from Godot import by its parent `.gdignore`.

The user identified the source as generated with BFL FLUX. The exact FLUX job identifier, model-version pin, and generation prompt are not recoverable from the MP4 metadata or searchable local session history, so this record does not invent them.

## Source clip

[`verbendings_intro_third_pass.mp4`](verbendings_intro_third_pass.mp4) is the byte-identical original MP4 retained without transcoding.

Its verified media contract is:

- SHA-256 `00fafb7706e6e64d37b71dbecb7beebf01fa014143a0fffea6383ee539c94bd1`;
- `20,532,753` bytes;
- `20.041667` seconds;
- H.264 video, `1280 × 704`, `24 fps`, YUV 4:2:0;
- AAC mono audio, `44.1 kHz`.

[`contact_sheet.png`](contact_sheet.png) and [`frames/`](frames/) are deterministic samples at 0, 4, 8, 12, and 16 seconds. [`VIDEO_EVIDENCE.json`](VIDEO_EVIDENCE.json) records their hashes, dimensions, and media metadata.

## Visual disposition

The clip establishes useful intro evidence:

- the Compound interior and elevated Researcher context;
- Semantic Engine machinery and a Subject-forming area;
- cyan, green, and pink Subject colour ordering; and
- the synchronised generated audio supplied with the clip.

It is **not** a runtime placeholder. Its ending presents the three Subjects at adjacent outlets rather than visibly forming them one by one through one shared nozzle and one landing pad. Current [`WORLD_DESIGN.md`](../../../WORLD_DESIGN.md) remains authoritative for implemented spatial and visual rules.

No scene, script, project setting, or runtime export references this third-pass source.

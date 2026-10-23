# Sheet batch 2 — A–C heroes + material board

**Date:** 2026-10-24  
**Scope:** Benjamin — production sheet rewrites for Meshy readiness on Priority A–C heroes. Modular kit bays stay Blender. No Meshy spend in this PR.

## Delivered

| Family | New primary sheet | Brief |
| --- | --- | --- |
| Facility material board | `docs/art/shared/references/facility_material_board_production.png` | `docs/art/shared/BRIEF_material_board.md` |
| Researcher booth | `docs/art/compound/researcher_booth/references/researcher_booth_production.png` | `docs/art/compound/researcher_booth/BRIEF.md` |
| Dispensing Line | `docs/art/compound/dispensing_line/references/dispensing_line_production.png` | `docs/art/compound/dispensing_line/BRIEF.md` |
| Drop / Recall | `docs/art/compound/drop_recall/references/drop_recall_production.png` | `docs/art/compound/drop_recall/BRIEF.md` |
| Central Core | `docs/art/compound/central_core/references/central_core_production.png` | `docs/art/compound/central_core/BRIEF.md` |
| Semantic Engine interfaces | `docs/art/shared/references/semantic_engine_interfaces_production.png` | `docs/art/shared/BRIEF_semantic_engine.md` |
| Breakable Material housing | `docs/art/applied_attrition/breakable_material_housing/references/breakable_material_housing_production.png` | `…/BRIEF.md` |
| 4 m shutter hero | `docs/art/kit/shutter_4m/references/shutter_4m_production.png` | `docs/art/kit/shutter_4m/BRIEF.md` |

Catalog thumbs under `docs/art/reference_sheets/` for the matching families were replaced with these production sheets.

## Known review flags

1. Material board still leans toward sample modules more than pure swatches — confirm palette coverage before Meshy.
2. Researcher booth may show console glow/panels; no readable UI text should survive into Meshy crops.
3. Drop/Recall banks must be exactly **3×8 = 24** sockets — verify cell count before crops.
4. Breakable housing interior Material must stay soft-substrate droplets (not granular fill / gore).
5. Dispensing Line hero is nodes only — not a full Compound span.
6. 4 m shutter is optional if Scenario door + Blender frame suffice.

## Not in this PR

Meshy runs, Scenario donors, Blender kit primitives, actor sheets (#85).


## Meshy crops (batch 2)

Unretouched geometric crops from the accepted production sheets above. All crops are 640×640 PNG padded with sheet background. **No Meshy spend in this PR.**

| Family | `meshy_inputs/` | Primary set |
| --- | --- | --- |
| Researcher booth | `docs/art/compound/researcher_booth/meshy_inputs/` | `front`, `side`, `back`, `three_quarter` (+ platform/interior detail) |
| Dispensing Line | `docs/art/compound/dispensing_line/meshy_inputs/` | `active_three_quarter`, `inactive_three_quarter` (sheet has two states only) |
| Drop / Recall | `docs/art/compound/drop_recall/meshy_inputs/` | modules + `bank_rails` |
| Central Core | `docs/art/compound/central_core/meshy_inputs/` | `intact_a`–`d`, cutaway, platform, dark, damaged |
| Semantic Engine | `docs/art/shared/semantic_engine/meshy_inputs/` | monitor, printer, dial, console, dock, card_reader |
| Breakable housing | `docs/art/applied_attrition/breakable_material_housing/meshy_inputs/` | intact → shattered |
| 4 m shutter | `docs/art/kit/shutter_4m/meshy_inputs/` | front_closed/open, side, rear_three_quarter |
| Facility material board | `docs/art/shared/facility_material_board/meshy_inputs/` | panels + materials_row |

### Crop-time flags (carry forward)

1. Drop/Recall bank rails on the sheet are **~3×10–12 sockets**, not the canon **3×8=24** — Meshy Desk must not treat bank_rails as scale-correct without a rewrite.
2. Breakable housing breached/shattered interiors still read **granular**, not soft-substrate droplets.
3. Booth interior/console crops may retain glow/panels — strip readable UI before spend if any appears.
4. Dispensing Line has only two sheet angles (active/inactive); Meshy propose should note limited view coverage.
5. Material board remains module-lean; crops are shared-language references, not a single hero mesh.

Meshy Desk proposes under parked ≤30/run ≤90 only after Bench pings with these paths.

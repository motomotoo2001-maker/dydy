# Battle Chess Revival — Development Plan

This is the durable roadmap for continuing the project without losing the next steps.
Keep one verified checkpoint behind us, one active milestone in progress, and at least two upcoming milestones already specified.

Last updated: 2026-10-03.

## Verified checkpoint

**Board presentation + production pawn pipeline**

Verified commits:
- `cd9c3ac` — Blender-built/rigged production pawns are generated in CI.
- `19008238` — durable roadmap after selection/move/check/checkmate presentation work.
- Godot 4.7.2 CI is green through the presentation milestone.

Verified features:
- complete playable chess rules + deterministic Black AI;
- 64 board sockets / 32 pieces;
- six signature capture cinematics;
- selected-piece pose, move anticipation/recovery, per-piece secondary motion;
- check reaction and checkmate winner/loser presentation;
- V3 external GLB pipeline for all six families on both sides;
- Blender production pawn pass, with the authored White Pawn kept on `white_pawn_production_v1.glb`;
- automated gameplay/battle/lineup renders and Visual QA.

Current QA direction from the latest render:
- silhouette/detail density still needs a major authored-mesh upgrade;
- framing/coarse composition remains farther from the target than palette/detail;
- battle materials still need later palette tuning.

## ACTIVE — Milestone B: Production V4 final character pipeline

Goal: replace the generated V3/blockout-looking families with genuinely authored, organic, high-detail characters while preserving the current gameplay and capture contracts.

Production order:
1. Knight pair.
2. Bishop pair.
3. Rook pair.
4. Queen pair.
5. King pair.
6. Final Pawn polish after the other silhouettes are locked.

### B1 — Knight pair (verified)

Deliverables:
- high-detail White Knight and Black Knight models with clearly different personalities;
- readable silhouette at gameplay-camera distance;
- production materials rather than flat blockout surfaces;
- correct board footprint and scale;
- stable forward axis/pivot;
- named animation parts or Skeleton3D/bone mapping compatible with existing capture logic;
- gameplay + battle + lineup render review;
- retain V3 Knight fallback until the production pair passes CI and visual review.

Exit gate:
- both production Knight assets instantiate in non-headless gameplay;
- `CHESS_RULES_PASS` and `BATTLE_CHESS_SMOKE_PASS`;
- Visual QA regression gate passes;
- screenshots visibly show the production Knight pair rather than fallback V3 models.

## VERIFIED — Milestone B2: Bishop production pair

Verified at `d3a39e8`:
- White Bishop production V1: 62 named parts;
- Black Bishop production V1: 65 named parts;
- required Head / Trunk / V3_TrunkTip / Staff / V3_CapeLayer hooks preserved;
- ram-charge capture smoke and rendered impact verified;
- production Knight and Bishop canonical forward axes normalized in PieceView;
- Godot 4.7.2 import, chess rules, battle smoke and Visual QA all green;
- front close-up reviews inspected after axis correction.

## VERIFIED — Milestone B3: Rook production pair

Verified at `42ece51`:
- White Rook production V1: 63 named parts;
- Black Rook production V1: 68 named parts;
- TowerCore / CrownBase / Arm_* / Fist_* / V3_FistKnuckle* / V3_TabardPoint hooks preserved;
- jump-crush smoke/capture render verified;
- close White/Black Rook reviews inspected;
- Godot 4.7.2 import, chess rules, battle smoke and Visual QA all green.

## VERIFIED — Milestone B4: Queen production pair

Verified at `42a2312`:
- White/Black Queen production V1: 61 named parts each;
- Staff / MagicOrb / V3_HairCurl* / V3_Cape* hooks preserved;
- transformation capture render verified;
- close White/Black Queen reviews inspected;
- Godot 4.7.2 import, chess rules, battle smoke and Visual QA all green.

## VERIFIED — Milestone B5: King production pair

Verified at `78fca9a`:
- White King production V1: 62 named parts;
- Black King production V1: 63 named parts;
- Head / Beard / Moustache / CrownBand / Scepter / Arm_* / V3_CoatPanel hooks preserved;
- trapdoor capture render verified;
- close White/Black King reviews inspected;
- Godot 4.7.2 import, chess rules, battle smoke and Visual QA all green.

### Production V1 army milestone complete

All six families now use production asset pipelines:
Pawn → Knight → Bishop → Rook → Queen → King.

A complete verified source ZIP was saved to Google Drive as
`BattleChessRevival_ALL_PRODUCTION_FAMILIES_V1_FINAL_2026-10-03_78fca9a.zip`.

## ACTIVE — Milestone C1: Skeleton3D + authored Knight animation

Start with Knight because it has the most demanding body hierarchy.

Checkpoint `9b0a98a` verified:
- White/Black Knight rigged GLBs generated beside the production-static source;
- 13-bone Skeleton3D imported on both sides;
- seven authored clips imported on both sides: Idle, Selected, Move, Hit, Victory, Defeat, DoubleKick;
- PieceView now loads the rigged Knight GLBs in normal rendering;
- complete chess/battle/render/Visual-QA suite remains green;
- Drive checkpoint saved as `BattleChessRevival_KNIGHT_RIGGED_V1_CHECKPOINT_2026-10-03_9b0a98a.zip`.

Current task:
- wire AnimationPlayer clips into selection, move, hit, victory and defeat states;
- replace Knight double-kick named-part fallback with the authored DoubleKick clip while keeping impact/VFX/camera timing;
- add a rendered authored-animation review gate;
- only remove Knight fallback transforms after the authored capture is visually verified.

## NEXT — Milestone C2: Bishop authored rig/animation

- Skeleton3D mapping for head/trunk/staff/cape;
- authored Idle / Move / Hit / Victory / Defeat;
- authored ram-charge signature capture.

## NEXT + 1 — Milestone C3/C4: Rook and Queen authored rigs

Rook: articulated arms/fists + jump-crush.
Queen: hair/cape/staff + transformation spell.

Then King and Pawn final authored-animation passes.

Knight B1 verified at `26e07749`: production White/Black Knight GLBs are generated in Blender, contracts pass (72/78 parts), gameplay/capture tests pass, close front review renders verified, and Visual QA regression gate passes.

Each family ships independently and keeps the previous verified asset as rollback.

## NEXT + 1 — Milestone B4/B5: Queen and King production pairs

Queen:
- strong face/hair/cape/staff silhouette and readable magic focal point;
- transformation capture compatibility.

King:
- expressive royal/demon-lord contrast, crown/scepter/cape detail;
- trapdoor capture compatibility.

## Milestone C: authored rig + animation clips

For each final production family:
1. Skeleton3D / skin binding.
2. Idle.
3. Selected.
4. Move.
5. Hit.
6. Victory.
7. Defeat/death.
8. Signature capture clip(s).
9. Animation event markers for VFX/audio/camera impacts.

The current named-part animation system remains as fallback/timing reference until each authored clip is verified.

## Milestone D: environment/material final pass

- authored cathedral meshes rather than blockout-only architecture;
- higher-frequency marble/wood/gold material detail;
- stained-glass light shaping;
- shadow/contact tuning under every piece;
- battle-camera exposure/DOF/framing pass;
- final gameplay and capture composition against the approved reference.

## Milestone E: UX/audio/polish

- title / mode / restart UI;
- check/checkmate presentation polish;
- piece selection and move SFX;
- unique signature-capture SFX;
- ambient cathedral bed;
- settings and volume controls;
- short onboarding hints.

## Milestone F: optimization + release candidate

- LOD / material / draw-call review;
- asset validation and missing-reference checks;
- deterministic smoke/rules suite;
- screenshot/Visual-QA regression gate;
- Windows package;
- versioned source ZIP + Google Drive checkpoint + updated PROJECT STATE.

## Checkpoint policy

Every meaningful milestone follows this order:
1. modify the working project;
2. run local/static/asset checks available in the environment;
3. commit to `battle-chess-revival`;
4. wait for Godot 4.7.2 CI validation;
5. inspect generated gameplay/battle/lineup captures;
6. only then create a new versioned ZIP;
7. save the ZIP to the `Battle Chess Revival` Drive folder;
8. update `Battle Chess Revival — PROJECT STATE` with the verified commit and next milestone.

## Recovery policy

- Source mesh generators and Blender scripts are first-class project source; generated GLBs may be rebuilt in CI.
- Production build artifacts must contain the generated GLBs actually used by Godot.
- Never replace a higher-quality production asset with a lower-fidelity concept asset merely because the concept binary exists in source backup.

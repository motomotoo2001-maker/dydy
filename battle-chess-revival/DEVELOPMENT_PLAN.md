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

## VERIFIED — Milestone C1: Skeleton3D + authored Knight animation

Final checkpoint `41d4cea` verified:
- White/Black Knight rigged GLBs use 13-bone Skeleton3D hierarchies;
- seven authored clips imported on both sides: Idle, Selected, Move, Hit, Victory, Defeat, DoubleKick;
- PieceView drives Idle / Selected / Move / Hit / Victory / Defeat through AnimationPlayer;
- BattleDirector uses the authored DoubleKick clip with deterministic camera/VFX timing;
- a short impact hit-stop keeps attacker and victim readable before launch;
- an Xvfb runtime gate exercises PieceView clip switching on both sides;
- dedicated rendered Hit and DoubleKick diagnostic poses were inspected;
- chess rules, capture smoke, gameplay renders and Visual QA are green;
- Drive checkpoint: `BattleChessRevival_KNIGHT_AUTHORED_C1_FINAL_2026-10-03_41d4cea.zip`.

The old named-part Knight sequence remains only as a safe fallback if an authored clip is unavailable.

## VERIFIED — Milestone C2: Bishop authored rig/animation

Final checkpoint `985377d` verified:
- White/Black Bishop rigged GLBs import as Skeleton3D + AnimationPlayer;
- authored Idle, Selected, Move, Hit, Victory, Defeat and RamCharge clips are available on both sides;
- PieceView drives Bishop presentation clips through the generalized authored-animation runtime;
- BattleDirector uses authored RamCharge with deterministic world-space charge, camera, VFX and victim launch timing;
- grounded-impact polish keeps the rigid robe seated on the chess pedestal at contact;
- dedicated Bishop Hit/RamCharge diagnostics, gameplay renders and Visual QA are green;
- Drive checkpoint: `BattleChessRevival_BISHOP_AUTHORED_C2_FINAL_2026-10-03_985377d.zip`.

The old named-part Bishop ram remains only as fallback when the authored clip is unavailable.

## VERIFIED — Milestone C3: Rook authored rig/animation

Final checkpoint `b4335b8` verified:
- White/Black Rook rigged GLBs import as Skeleton3D + AnimationPlayer;
- authored Idle, Selected, Move, Hit, Victory, Defeat and JumpCrush clips are available on both sides;
- PieceView drives Rook presentation clips through the generalized authored-animation runtime;
- BattleDirector uses authored JumpCrush while retaining deterministic jump/drop, shadow, impact VFX and victim squash;
- dedicated Rook Hit/JumpCrush diagnostics and the battle capture were visually inspected;
- chess rules, capture smoke, gameplay renders and Visual QA are green;
- Drive checkpoint: `BattleChessRevival_ROOK_AUTHORED_C3_FINAL_2026-10-03_b4335b8.zip`.

The named-part Rook crush remains as fallback when the authored clip is unavailable.

## VERIFIED — Milestone C4: Queen authored rig/animation

Final checkpoint `bafb22f` verified:
- White/Black Queen rigged GLBs import as Skeleton3D + AnimationPlayer;
- nine-bone hierarchy covers body/head/hair/cape/arms/staff/orb;
- authored Idle, Selected, Move, Hit, Victory, Defeat and TransformSpell clips are available on both sides;
- PieceView drives Queen presentation clips through the shared authored-animation runtime;
- BattleDirector uses TransformSpell for Queen body motion while smoke/hearts/POOF/replacement spawning stay deterministic;
- dedicated Queen Hit/TransformSpell diagnostics and battle capture were visually inspected;
- chess rules, capture smoke, gameplay renders and Visual QA are green;
- Drive checkpoint: `BattleChessRevival_QUEEN_AUTHORED_C4_FINAL_2026-10-03_bafb22f.zip`.

## ACTIVE — Milestone C5: King authored rig/animation

Current task:
- create White/Black King rigged candidates beside production GLBs;
- Skeleton3D mapping for root/body/head/beard/arms/scepter/coat-cape;
- authored Idle, Selected, Move, Hit, Victory, Defeat and TrapdoorCommand clips;
- validate candidates before switching PieceView;
- keep remote control, trapdoor geometry, victim fall and VFX deterministic in BattleDirector;
- add King Hit/TrapdoorCommand diagnostic renders;
- preserve named-part trapdoor pose as fallback until visual verification.

## NEXT — Milestone C6: Pawn final authored-animation unification

- normalize White/Black pawn asset naming and animation contract;
- authored Idle / Selected / Move / Hit / Victory / Defeat;
- keep/refine ToeStab signature animation;
- final full-army authored-animation lineup and capture review.

## AFTER C6 — Milestone D

Environment/material final pass, followed by UX/audio polish and release-candidate optimization.

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

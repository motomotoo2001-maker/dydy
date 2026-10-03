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

### B1 — Knight pair (current task)

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

## NEXT — Milestone B2/B3: Bishop and Rook production pairs

Bishop:
- elephant/cleric silhouette, expressive trunk/head, staff, cloth layers;
- ram-charge capture compatibility.

Rook:
- massive fortress/bruiser silhouette, articulated arms/fists;
- jump-crush capture compatibility.

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

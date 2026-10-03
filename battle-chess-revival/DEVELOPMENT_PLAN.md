# Battle Chess Revival — Development Plan

This file is the durable roadmap for continuing the project without losing the next steps.
The rule is simple: keep one verified checkpoint behind us, one active milestone in progress,
and at least two upcoming milestones already specified.

Last updated: 2026-10-03.

## Verified checkpoint

**Production V3 Animation Backup — commit `3b8d4b4`**

- Playable chess rules + deterministic Black AI.
- 64 board sockets / 32 pieces.
- Six signature capture cinematics.
- White/Black V3 GLB assets for Pawn, Knight, Bishop, Rook, Queen, King.
- Imported named-part articulation, idle motion, VFX polish, render captures and Visual QA.
- Google Drive backup: `BattleChessRevival_CONCEPT_V3_ANIMATION_BACKUP_2026-10-02_3b8d4b4.zip`.

## ACTIVE — Milestone A0: restore V3 binary assets to GitHub

A recovery audit on 2026-10-03 found that `PieceView` references the external V3 GLBs,
but the GLB binaries themselves are absent from the GitHub branch. This forces the game to
fall back to procedural production blockouts even though the Drive checkpoint contains the models.

Immediate deliverables:

- restore the 12 required V3 GLBs from the verified Drive backup into `assets/models/`;
- change White Pawn from the stale `white_pawn_production_v1.glb` path to the existing
  `white_pawn_concept_v3.glb` asset;
- retain procedural blockouts as a safe fallback;
- run Godot 4.7.2 import/parse, chess rules, smoke tests and Visual QA;
- inspect gameplay/battle/lineup captures and correct scale/orientation/material issues before
  freezing a new baseline;
- create a new Drive checkpoint only after the render is verified.

Exit gate: all 12 GLBs are present in GitHub, non-headless gameplay uses them, tests pass,
and generated reference captures visibly contain the external models.

## NEXT — Milestone A1: board-game presentation animation

Goal: make the pieces feel alive outside capture cinematics before replacing V3 meshes with final authored V4 characters.

Deliverables:

- selected-piece lift / scale pose;
- move anticipation + recovery pose;
- per-piece secondary motion during movement;
- check reaction for the threatened King;
- checkmate winner/loser poses;
- headless smoke coverage for the presentation APIs;
- CI verification on Godot 4.7.2 before making a new Drive checkpoint.

Exit gate: `CHESS_RULES_PASS`, `BATTLE_CHESS_SMOKE_PASS`, render/Visual-QA pass, no parser/runtime regression.

## NEXT + 1 — Milestone B: Production V4 final character pipeline

Goal: replace V3 concept meshes / procedural fallbacks with genuinely authored organic meshes while preserving the current gameplay contract.

Order: Knight → Bishop → Rook → Queen → King → final Pawn polish.

Each family must keep:

- correct chess-square footprint;
- named animation anchors / parts or Skeleton3D bone mapping;
- team-readable silhouette at gameplay-camera distance;
- PBR material separation;
- capture compatibility;
- fallback V3 asset until the V4 import passes CI and screenshot review.

Do not replace all 12 assets at once. Ship one family at a time and keep the last verified family available for rollback.

## AFTER THAT — Milestone C: rig + authored clips

For each final character family:

1. Skeleton3D / skin binding.
2. Idle.
3. Selected.
4. Move.
5. Hit.
6. Victory.
7. Defeat/death.
8. Signature capture clip(s).
9. Animation event markers for VFX/audio/camera impact.

The current named-part animation system remains as a fallback and timing reference until the authored clip is verified.

## Milestone D: environment/material final pass

- authored cathedral meshes rather than blockout-only architecture;
- higher-frequency marble/wood/gold material detail;
- stained-glass light shaping;
- shadow/contact tuning under every piece;
- battle-camera exposure/DOF pass;
- final gameplay and capture composition against the approved reference.

## Milestone E: UX/audio/polish

- title / mode / restart UI;
- check/checkmate presentation;
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
2. run local static/asset checks available in the environment;
3. commit to `battle-chess-revival`;
4. wait for Godot 4.7.2 CI validation;
5. inspect generated gameplay/battle/lineup captures when available;
6. only then create a new versioned ZIP;
7. save the ZIP to the `Battle Chess Revival` Drive folder;
8. update `Battle Chess Revival — PROJECT STATE` with the verified commit and the next milestone.

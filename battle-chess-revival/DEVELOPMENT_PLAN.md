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

## VERIFIED — Milestone C5: King authored rig/animation

Final checkpoint `2d909c2` verified:
- White/Black King rigged GLBs import as Skeleton3D + AnimationPlayer;
- authored Idle, Selected, Move, Hit, Victory, Defeat and TrapdoorCommand clips are available on both sides;
- PieceView drives King presentation clips through the shared authored-animation runtime;
- BattleDirector uses TrapdoorCommand for King body motion while remote/trapdoor/victim fall/VFX remain deterministic;
- dedicated King Hit/TrapdoorCommand diagnostics and battle capture were visually inspected;
- chess rules, capture smoke, gameplay renders and Visual QA are green;
- Drive checkpoint: `BattleChessRevival_KING_AUTHORED_C5_FINAL_2026-10-03_2d909c2.zip`.

## VERIFIED — Milestone C6: Pawn final authored-animation unification

Final checkpoint `0fa17ca` verified:
- White/Black Pawn assets use unified production naming;
- both Pawn sides import full Skeleton3D + authored animation contracts;
- authored Idle, Selected, Move, Hit, Victory, Defeat and ToeStab are available on both sides;
- PieceView drives Pawn gameplay presentation through the same authored-animation runtime as every other family;
- BattleDirector uses authored ToeStab while preserving deterministic BAM/VFX/victim bounce timing;
- dedicated Pawn Hit/ToeStab diagnostics and full capture suite were visually inspected;
- all six families pass one combined rig/runtime/chess/capture/render/Visual-QA workflow;
- Drive checkpoint: `BattleChessRevival_ALL_AUTHORED_CHARACTERS_C6_FINAL_2026-10-03_0fa17ca.zip`.

### Authored character-animation milestone complete

Every family now has a verified production model + Skeleton3D + gameplay/capture clips:
Pawn → Knight → Bishop → Rook → Queen → King.

## VERIFIED — Milestone D1: Production cathedral architecture

Final checkpoint `d683952` verified:
- Blender-authored CathedralProductionV1 GLB integrated as the normal rendered environment;
- procedural cathedral remains available as the headless/safe fallback;
- production shell includes compound columns, arches, altar/dais, stained-glass bays, statues, banners, candle groups and visible vault/ridge structure;
- dedicated Godot cathedral asset gate validates mesh density and key architecture nodes;
- all character/runtime/chess/capture tests remain green with the external cathedral;
- gameplay/battle renders and Visual QA pass;
- Drive checkpoint: `BattleChessRevival_CATHEDRAL_D1_FINAL_2026-10-03_d683952.zip`.

## VERIFIED — Milestone D2: material + stained-glass lighting pass

Final checkpoint `546fa33` verified:
- production cathedral receives runtime stone/gold/cloth/emissive-glass material overrides;
- stone uses procedural albedo/roughness variation instead of a flat beige response;
- stained-glass red/gold/blue lights softly shape the cathedral without recoloring pieces;
- ambient/sun/fill balance was reduced for stronger depth and preserved black-side readability;
- gameplay/battle renders and Visual QA remain green;
- Drive checkpoint: `BattleChessRevival_CATHEDRAL_D2_MATERIAL_LIGHTING_FINAL_2026-10-03_546fa33.zip`.

## VERIFIED — Milestone D3: camera/contact/final composition

Final checkpoint `e7c9382` verified:
- gameplay camera lowered/opened to show cathedral depth while keeping the complete board readable;
- battle camera tightened with lighter DOF for authored capture clarity;
- SSAO/shadow-distance tuning improves piece-base grounding without dirtying white materials;
- all six capture compositions were reviewed after the camera change;
- full Godot 4.7.2 CI, gameplay/battle renders and Visual QA are green;
- Drive checkpoint: `BattleChessRevival_FINAL_VISUAL_D3_2026-10-03_e7c9382.zip`.

### Final visual-composition baseline complete

Production characters, authored animations, cathedral architecture, materials, stained-glass lighting and final camera/contact composition are now under one verified baseline.

### User-directed gameplay camera revision

Verified at `7f7db76`:
- gameplay camera moved to a 3/4 side angle from the open front-right cathedral entrance;
- complete board frame remains visible in the 1280×720 gameplay render;
- White and Black armies continue facing each other correctly;
- production UI, all authored rig/runtime tests, chess rules, capture smoke and Visual QA pass;
- CI now retains visual artifacts even when a future Visual QA comparison fails;
- Drive checkpoint: `BattleChessRevival_SIDE_CAMERA_E1_CHECKPOINT_2026-10-03_7f7db76.zip`.

Fixed camera rule:
- gameplay = full-board 3/4 side angle;
- battle/capture = separate cinematic camera.

## VERIFIED — Milestone E1: UX / HUD / settings

Final checkpoint `7f7db76` + E1 HUD commits verified:
- compact production turn/status card replaces the debug HUD;
- help strip, check banner and pause/settings overlay preserve board visibility;
- Master/Ambience/SFX controls are available in pause settings;
- user-approved full-board 3/4 gameplay camera is locked;
- UI smoke, gameplay render and Visual QA are green;
- Drive checkpoint: `BattleChessRevival_E1_UX_SIDE_CAMERA_FINAL_2026-10-03_7f7db76.zip`.

## VERIFIED — Milestone E2: audio and feedback

Final checkpoint `4ec32ce` verified:
- deterministic CI audio pack builds 11 WAV assets;
- looped cathedral ambience plus selection/move/check/checkmate feedback;
- unique Pawn/Knight/Bishop/Rook/Queen/King signature impact sounds;
- AudioDirector routes gameplay/BattleDirector events through Ambience and SFX buses;
- Master/Ambience/SFX sliders are wired and covered by UI/audio smoke tests;
- complete rig/rules/capture/render/Visual-QA workflow remains green;
- Drive checkpoint: `BattleChessRevival_E2_AUDIO_FINAL_2026-10-03_4ec32ce.zip`.

## VERIFIED — Milestone E3: final presentation polish

Final presentation verified:
- short title/intro presentation integrated for normal gameplay;
- terminal-state overlay covers checkmate/draw outcomes;
- rematch button + keyboard rematch flow are covered by smoke tests;
- terminal game states lock further board input correctly;
- production HUD/audio/camera baselines remain green.

## VERIFIED — Milestone F: optimization and release candidate

### RC1 verified at `e404dbc`

- release audit validates resources, cameras and shared runtime materials;
- cathedral runtime materials are shared to reduce duplicate material instances;
- Windows x86_64 export preset is present and validated in CI;
- Windows artifact contains a runnable `BattleChessRevival.exe` (157,582,344 bytes inside the packaged artifact);
- source artifact contains the Godot 4.7.2 project, asset generators, tests and visual references;
- full CI including UI, audio, all authored rigs, chess rules, capture smoke, render and Visual QA is green;
- Google Drive backups:
  - `BattleChessRevival_RC1_Windows_x86_64_2026-10-03_e404dbc.zip`
  - `BattleChessRevival_RC1_Source_Godot_4.7.2_2026-10-03_e404dbc.zip`

RC2 verified at `cd20018`:
- full regression CI is green after release-packaging changes;
- Windows ZIP contains `BattleChessRevival.exe` + `README.txt`;
- source ZIP contains the Godot project/tooling but excludes generated gameplay/capture/review PNGs;
- source artifact dropped from ~62.8 MB to ~45.9 MB without removing production source;
- Visual QA remains green;
- Windows export remains a single-file Godot build (~157.6 MB executable);
- Google Drive backups:
  - `BattleChessRevival_RC2_Windows_x86_64_2026-10-03_cd20018.zip`
  - `BattleChessRevival_RC2_Source_Godot_4.7.2_2026-10-03_cd20018.zip`

### Release-candidate freeze

RC2 is the current verified release candidate.

## VERIFIED — Milestone G1: post-RC gameplay/visual refinement

Verified visual progression:
- `4d9a2fb`: foreground-occlusion camera cleanup + approved G1 rebaseline;
- `eeef0fb`: warmer cathedral bounce/window light, gameplay similarity 76.9% → 78.6%;
- `5f64732`: authored cathedral detail pass, gameplay similarity 78.6% → 79.0%, edge/detail density 74.1% → 77.5%;
- complete board remains visible from the locked 3/4 gameplay camera;
- all authored rigs, captures, audio, UI, Visual QA and Windows export remain green;
- Drive checkpoints saved for camera, warm-light and detail variants.

Current best G1 rollback:
- `BattleChessRevival_G1_Detail_Windows_2026-10-03_5f64732.zip`
- `BattleChessRevival_G1_Detail_Source_2026-10-03_5f64732.zip`

## VERIFIED — Milestone G2: final public build polish

Verified checkpoint `4f5ca10`:
- premium board inlays/coordinates, last-move highlights and check-danger feedback are integrated;
- AI/local game mode selector, strategic AI difficulty levels and interactive underpromotion are verified;
- move history/Undo, threefold repetition and expanded insufficient-material/castling validation remain green;
- battle presentation adds signature aura, warmer/neutral capture lighting, shared anticipation/recovery beats and lens-kick impact feedback;
- game mode, AI difficulty and Master/Ambience/SFX settings persist through restart via ConfigFile;
- pause menu includes a full numbered move-history panel;
- complete UI/audio/rules/rig/capture/render/Visual-QA/Windows-export pipeline is green;
- Drive backups:
  - `BattleChessRevival_G2_Windows_2026-10-03_4f5ca10.zip`
  - `BattleChessRevival_G2_Source_2026-10-03_4f5ca10.zip`.

## VERIFIED — Milestone G3: final public release freeze

Verified public build `ed1aca0`:
- Low / Medium / High graphics-quality presets are exposed, persistent and covered by runtime tests;
- High remains the locked reference-quality look;
- final release audit, UI/audio/rules/rig/capture/render/Visual-QA and Windows export are green;
- Windows package contains `BattleChessRevival.exe` + release README;
- source package contains the Godot 4.7.2 project/tooling with generated QA PNGs excluded;
- public README/settings/control documentation refreshed;
- Drive backups:
  - `BattleChessRevival_G3_PUBLIC_Windows_x86_64_2026-10-04_ed1aca0.zip`
  - `BattleChessRevival_G3_PUBLIC_Source_Godot_4.7.2_2026-10-04_ed1aca0.zip`.

## VERIFIED — Milestone G4: battle palette + visual fidelity

Verified checkpoint `90ca30a`:
- battle-only environment/light palette tuned without changing gameplay visuals;
- battle reference similarity improved from 79.3% to 83.3%;
- battle palette similarity improved from 65.6% to 73.4%;
- battle temperature similarity reached 98.0% and brightness 99.2%;
- gameplay reference remains stable at 79.0%;
- full UI/settings/rig/AI/history/promotion/rules/capture/render/Visual-QA/Windows-export pipeline is green;
- Drive backups:
  - `BattleChessRevival_G4_BattlePalette_Windows_2026-10-04_90ca30a.zip`
  - `BattleChessRevival_G4_BattlePalette_Source_2026-10-04_90ca30a.zip`.

## ACTIVE — Milestone G5: authored animation + cinematic transition polish

Current task:
- soften the hard gameplay→battle camera switch with a short authored push-in;
- add a controlled recovery pull-out before returning to gameplay;
- preserve all signature impact timings and authored Skeleton3D clips;
- keep G4 battle palette metrics and G3 gameplay camera locked;
- validate capture smoke + rendered contact sheet before checkpoint.

## AFTER E — Milestone F: optimization and release candidate

- LOD/material/draw-call review;
- final missing-reference validation;
- Windows export/package;
- release-candidate smoke/render gate;
- final versioned source ZIP + Google Drive checkpoint + PROJECT STATE update.

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

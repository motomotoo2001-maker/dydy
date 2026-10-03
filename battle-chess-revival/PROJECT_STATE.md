# Battle Chess Revival — Project State

Last verified release candidate: **RC2**
Verified branch: `battle-chess-revival`
Verified commit before this state file: `cd20018`
Engine: **Godot 4.7.2 stable**
Target release: **Windows x86_64**

## Current verified product

- Complete legal chess layer with deterministic Black AI.
- White/Black production characters for Pawn, Knight, Bishop, Rook, Queen and King.
- Skeleton3D authored clips for all six families.
- Six cinematic signature captures.
- Production cathedral environment, materials, stained-glass lighting and contact grounding.
- Fixed gameplay camera: full-board 3/4 side view.
- Separate cinematic battle/capture camera.
- Production HUD, pause/settings, onboarding hints, check/checkmate/endgame/rematch presentation.
- Cathedral ambience and gameplay/capture SFX.
- Windows export validated in CI.

## Verified RC2 artifacts

Windows:
`BattleChessRevival_RC2_Windows_x86_64_2026-10-03_cd20018.zip`

Contents:
- `BattleChessRevival.exe`
- `README.txt`

Source:
`BattleChessRevival_RC2_Source_Godot_4.7.2_2026-10-03_cd20018.zip`

The source package intentionally excludes generated gameplay/capture/review PNGs; those remain CI QA artifacts.

Both RC2 ZIPs are backed up in the Battle Chess Revival Google Drive folder.

## Non-negotiable visual/gameplay rules

1. White pieces face Black; Black pieces face White.
2. Gameplay camera stays at a 3/4 side angle with the complete board visible.
3. Battle/capture camera remains separate and cinematic.
4. Production GLB/Skeleton3D assets remain the normal path; fallback animation/geometry stays only as safety.
5. RC2 is the rollback checkpoint for any post-RC work.

## Next milestone

**G1 — post-RC gameplay/visual refinement**

Only make changes that clearly improve the RC2 experience while keeping CI, Visual QA and Windows export green.

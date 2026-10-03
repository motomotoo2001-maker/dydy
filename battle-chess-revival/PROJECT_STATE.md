# Battle Chess Revival — Project State

Last verified release candidate: **G1 full-upgrade checkpoint**
Verified branch: `battle-chess-revival`
Latest verified post-RC visual checkpoint: `5f64732`
Stable release rollback: `cd20018` (RC2)
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

## Verified G1 full-upgrade artifacts

Windows:
`BattleChessRevival_FULL_UPGRADE_G1_Windows_2026-10-03_8dd5e66.zip`

Source:
`BattleChessRevival_FULL_UPGRADE_G1_Source_2026-10-03_8dd5e66.zip`

Both G1 ZIPs are backed up in the Battle Chess Revival Google Drive folder.

G1 additionally includes strategic AI difficulty levels, move history/Undo, threefold repetition, piece-specific board movement, landing VFX, warmer lighting and a denser authored cathedral.

## Non-negotiable visual/gameplay rules

1. White pieces face Black; Black pieces face White.
2. Gameplay camera stays at a 3/4 side angle with the complete board visible.
3. Battle/capture camera remains separate and cinematic.
4. Production GLB/Skeleton3D assets remain the normal path; fallback animation/geometry stays only as safety.
5. G1 full-upgrade checkpoint is the current rollback point; RC2 remains the older clean release-candidate fallback.

## Post-RC verified visual improvements

- Camera cleanup: foreground architecture no longer blocks the board.
- Warm-light pass: gameplay visual similarity improved from 76.9% to 78.6%.
- Cathedral authored-detail pass: gameplay similarity improved to 79.0%; edge/detail density improved to 77.5%.
- Latest G1 Drive backups:
  - `BattleChessRevival_G1_Detail_Windows_2026-10-03_5f64732.zip`
  - `BattleChessRevival_G1_Detail_Source_2026-10-03_5f64732.zip`

## Next milestone

**G2 — final public build polish**

Focus on board/material/prop detail and battle palette while preserving the locked camera, production assets, authored animations and RC2 rollback.

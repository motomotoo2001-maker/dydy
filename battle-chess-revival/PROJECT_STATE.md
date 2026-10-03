# Battle Chess Revival — Project State

Last verified release candidate: **G4 visual-fidelity checkpoint**
Verified branch: `battle-chess-revival`
Latest verified post-public checkpoint: `90ca30a`
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

## Verified G4 visual-fidelity artifacts

Windows:
`BattleChessRevival_G4_BattlePalette_Windows_2026-10-04_90ca30a.zip`

Source:
`BattleChessRevival_G4_BattlePalette_Source_2026-10-04_90ca30a.zip`

G4 improves the battle-only palette to 83.3% overall reference similarity while leaving gameplay at the locked 79.0% baseline.

## Verified G3 public artifacts

Windows:
`BattleChessRevival_G3_PUBLIC_Windows_x86_64_2026-10-04_ed1aca0.zip`

Source:
`BattleChessRevival_G3_PUBLIC_Source_Godot_4.7.2_2026-10-04_ed1aca0.zip`

Both G3 public ZIPs are backed up in the Battle Chess Revival Google Drive folder.

G3 adds persistent Low / Medium / High graphics-quality presets while preserving High as the locked reference-quality configuration.

## Verified G2 full-polish artifacts

Windows:
`BattleChessRevival_G2_Windows_2026-10-03_4f5ca10.zip`

Source:
`BattleChessRevival_G2_Source_2026-10-03_4f5ca10.zip`

Both G2 ZIPs are backed up in the Battle Chess Revival Google Drive folder.

G2 additionally includes premium board presentation, last-move/check overlays, explicit AI/local mode selection, full promotion choice, stronger battle presentation, persistent settings and a full pause-menu move history.

## Previous G1 full-upgrade artifacts

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
5. G2 full-polish checkpoint is the current rollback point; G1/RC2 remain older stable fallbacks.

## Post-RC verified visual improvements

- Camera cleanup: foreground architecture no longer blocks the board.
- Warm-light pass: gameplay visual similarity improved from 76.9% to 78.6%.
- Cathedral authored-detail pass: gameplay similarity improved to 79.0%; edge/detail density improved to 77.5%.
- Latest G1 Drive backups:
  - `BattleChessRevival_G1_Detail_Windows_2026-10-03_5f64732.zip`
  - `BattleChessRevival_G1_Detail_Source_2026-10-03_5f64732.zip`

## Next milestone

**G5 — authored animation + cinematic transition polish**

Improve camera transitions and capture presentation without changing authored impact timings, G4 battle palette, or the locked full-board gameplay camera.

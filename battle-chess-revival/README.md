# Battle Chess Revival — Godot 4.7.2 vertical slice

This branch contains a runnable 3D blockout for the Battle Chess-inspired project.

## Included now

- 8×8 marble-style board with 64 named sockets A1–H8.
- 32 placeholder 3D pieces at standard chess starting squares.
- cathedral blockout, stained-glass panels, warm/cool lighting, gameplay and battle cameras.
- data-driven capture registry.
- six approved comedy capture signatures:
  1. Pawn — toe stab.
  2. Knight — double hind kick.
  3. Bishop — ram charge.
  4. Rook — jump crush.
  5. Queen — magic transformation into rubber duck.
  6. King — remote-controlled trapdoor.
- headless smoke test that loads the scene and executes all six captures.

## Controls

Run the project and press keys 1 through 6 to preview each capture signature.

## Godot

Target: Godot 4.7.2 stable, GDScript.

The current characters are animation blockout placeholders. They are intentionally separated from final production meshes/rigs so timing and battle direction can be validated before final character art.


## Playable chess layer

The vertical slice includes real chess legality, check/checkmate/stalemate detection, castling, en passant, automatic queen promotion, a deterministic black AI, mouse square selection, legal-move highlights, and signature capture cinematics integrated into board captures.

Left-click a white piece and then a highlighted destination. Black replies automatically.


## Polish controls

R restarts the match. A toggles the black AI so local two-player testing is possible. Normal moves tween across the board; Knights use a short hop arc. Battle camera profiles vary by capture signature. Comic impact text is generated in 3D. Cathedral blockout includes arches, banners, statues and candle clusters. CI packages a downloadable source ZIP after all Godot tests pass.


## Visual target pass v1

The board now follows the approved video target: warm dark walnut squares, cream marble squares, a thick wooden frame with restrained gold trim, a brighter cathedral, warmer window light, and a closer 38-degree gameplay lens. White Pawns use the first production-style character blockout with a readable face, oversized helmet, ivory/blue/gold costume, shield, spear, boots, separated limbs, and dedicated battle anchors.

CI also renders a real gameplay frame from Godot and uploads it as the BattleChessRevival-Gameplay-Reference artifact, so visual changes can be inspected instead of only syntax-tested.


## Automated Visual QA

Every CI build now compares the rendered gameplay and battle frames with a compact profile extracted from the approved user-provided video reference. The check tracks lighting, contrast, saturation, warm/cool balance, material palette, edge/detail density, coarse composition, low-resolution perceptual difference, and a diagnostic SSIM value.

The Visual QA step writes `visual_report/report.json`, `report.md`, side-by-side diagnostics, and diff images. CI fails only on a meaningful regression from the verified baseline (default tolerance: 4 percentage points); the target-reference score itself remains a development metric while final production assets are still being built.

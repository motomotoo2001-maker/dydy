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


## Visual QA guided pass v2

The first automated report flagged over-bright lighting, weak board occupancy/framing, and low silhouette detail. This pass responds directly to those findings: the gameplay camera moves closer to the approved board composition, cathedral lighting is reduced toward the reference luminance, and Black Pawns receive a dedicated goblin production-style blockout with readable face, ears, bucket helmet, shield, armor and toe-stab knife.


## Knight production pass

White and Black Knights now use dedicated stylized horse-and-rider production blockouts instead of generic capsules. White uses an ivory horse, blue/gold tack, readable face, rider shield and compact lance. Black uses a lean nightmare horse, bony joints, violet emissive eyes, horns, dark rider and rune shield. The battle camera was lowered/closed in and battle-only warm lighting is reduced in response to Visual QA.


## Battle-reference correction

Visual QA showed the Knight pass improved gameplay but hurt the battle score. The capture stage now keeps the rest of the army visible as spectators, uses a lower 3/4 battle camera, removes the full-body red victim tint from Pawn impact, and further reduces warm battle-only light to prevent overexposed marble.


## Bishop production pass

Both Bishops now have dedicated silhouettes. White is an original elephant-cleric with huge ears, compact trunk, tall mitre, robe and glowing ceremonial staff; Black is a horned necromancer/ram-priest with bone mask, violet glow and pronged staff. This keeps the approved ram-charge animation readable while moving the army away from generic cylinders.


## Rook production pass

Rooks are no longer plain blocks. White is now a carved stone castle-golem with articulated arms, fists, angry glowing eyes, crenellations and heraldry. Black is an obsidian/lava tower-golem with emissive cracks, ember eyes, heavy fists and dark rune plate. The jump-crush capture continues to use the same BattleDirector timing and squash/stretch root.


## Queen production pass

Queens now have dedicated theatrical sorceress silhouettes. White uses an ivory/gold gown, crown, expressive face and cyan magic staff. Black uses an angular dark gown, horned crown, magenta emissive eyes and spell core. The existing smoke-swap capture pipeline remains data-driven and now has a much clearer caster silhouette.

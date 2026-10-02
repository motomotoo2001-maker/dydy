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

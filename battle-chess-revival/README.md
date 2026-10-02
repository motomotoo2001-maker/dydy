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


## King production pass

Kings now have dedicated personalities rather than generic columns. White is a broad comic old monarch with beard, oversized crown, robe, cape, scepter and cyan gems. Black is a red demon-lord with armor belly, fangs, horned crown, violet cape and emissive orange eyes. The red-button trapdoor remote remains an animation prop spawned by BattleDirector.


## Battle camera occlusion fix

The screenshot review caught an issue the numeric Visual QA did not: keeping both armies visible placed the low battle camera inside the near-side white formation. Capture focus now hides non-participating attacker-side pieces while keeping the victim army as background spectators, and the close camera was moved outside the board with a safer 3/4 composition.


## Cathedral/environment pass

The cathedral now gets three large emissive stained-glass windows on the visible left wall and two heraldic back-wall banners, bringing the gameplay composition closer to the approved reference. In Forward+ the battle camera also enables a restrained far depth-of-field blur so the victim army reads as spectators without competing with the capture action.


## Imported production asset pipeline — White Pawn

Asset production has moved beyond runtime primitive-only characters. CI now builds a real GLB file at `assets/models/white_pawn_refined_v1.glb` before Godot imports the project. The White Pawn loads that imported mesh scene first and falls back to the procedural blockout only if the asset is unavailable. The GLB contains 39 named mesh parts with PBR material groups (ivory, gold, blue, leather, skin, bronze, dark details), readable facial features, quilted tunic detail, helmet/cheek guards, shield and compact spear. Separate named parts are intentional preparation for the later Skeleton3D rigging pass.


## Imported production asset pipeline — Black Pawn

The Black Pawn now also uses a real generated/imported GLB instead of the runtime-only primitive character during rendered gameplay. Its geometry is deliberately asymmetric and separate from White: wide goblin ears, long nose, bucket helmet with patch/rivets, ragged dark armor, crooked shield, oversized hands/boots and a dedicated toe-stab knife. Both Pawn GLBs keep named parts for the later rig/Skeleton3D pass.


## Imported production asset pipeline — Knights

Both Knights now have real imported GLB scenes in rendered gameplay. White keeps the approved noble animated-film silhouette: broad ivory horse, expressive muzzle/eyes, blue mane and saddle cloth, gold bridle, compact rider, shield and lance. Black is structurally different: lean nightmare horse, exposed bony knees, horns, violet mane, dark armored rider with horned helmet and angular lance tip. Each GLB preserves named horse/rider/prop parts for the future rigging pass.


## Imported production asset milestone — full army

Every piece family now has a real imported White/Black GLB in rendered gameplay: Pawn, Knight, Bishop, Rook, Queen and King. The procedural builders remain only as safe headless/fallback implementations. The imported scenes preserve deliberately different team silhouettes and named sub-parts for the upcoming Skeleton3D rig pass. This completes the first asset-first conversion milestone before any new animation/VFX polish.


## Animation upgrade — articulated imported parts

Imported GLB transforms are now preserved as scene-node transforms rather than baked into vertex positions. That makes named sub-parts genuinely animation-ready. PieceView caches every imported part's rest transform and exposes prefix-based part lookup; capture choreography now articulates weapons, Knight legs/hooves, Bishop trunk/staff, Rook arms/fists, Queen staff, and King arms/scepter in addition to whole-body squash/stretch. Gameplay also gets per-piece subtle idle breathing/sway, disabled automatically during captures.

CI now captures the exact impact frame for all six signatures and assembles a 3x2 contact sheet, so animation regressions are visible in every build rather than only testing the Pawn capture.


## Animation/VFX polish pass

The imported asset milestone is followed by a dedicated motion pass. Idle motion now drives named GLB sub-parts (heads, crests, horse heads/manes, staffs, magic orbs, beards and scepters) instead of only bobbing the whole piece. Signature captures add camera punch, radial impact bursts and ground shockwaves at their main contact frames. The environment now uses AgX tonemapping with restrained highlight rolloff, and key warm lights cast shadows for stronger contact. CI publishes all six capture screenshots in addition to gameplay/battle reference frames.


## Concept-sheet integration v2

The approved character sheets are now the direct production target. All 12 imported GLBs moved to `*_concept_v2.glb` and receive a second authored detail pass after the base modular mesh is built. The pass adds the concept-specific visual language: White blue/gold heraldry, polished armor and cloth; Black crimson/bronze/purple accents; multi-part helmet plumes; tabards/capes; bishop inner ears and robe layers; rook heraldry/lava cracks; queen hair/cape/jewelry; king fur mantles/capes and crown/scepter gems. All added parts are named for animation rather than baked into a single mesh. Pawn and Knight capture motion now also drives plume/shield/rider/horse-head parts so the approved animation sheets begin to read in motion.

# BackpackRoyale_Rebuild

Clean rebuild for **Unity 6000.6.3f1**. The old `v0.3.x/v0.4.0` code, Packages, ProjectSettings, scenes, prefabs, asmdefs and DemoBuilder were not copied.

## Preserved visual assets
The approved source-art archive is kept in `Assets/Game/Art`: five character sheets, item/UI atlases, four VFX sheets, backgrounds and concept references. Generated sprites are created from these sources by editor bakers after Unity imports the project.

## Stability-first stack
Built-in Render Pipeline; legacy Input Manager (no `com.unity.inputsystem`); UGUI 2.6.0 + TextMeshPro; SpriteRenderer + Animator; ParticleSystem; ScriptableObjects; Unity Test Framework 1.8.0.

## v0.1.5 visual cleanup
This pass is based on the first real Unity 6000.6.3f1 screenshots of the generated demo.
- Build mode no longer overlays live controls on the painted `build_camp.png` UI mockup; it uses a clean generated arena backdrop.
- Hero Select also uses a clean generated arena rather than a menu mockup with baked buttons.
- Build mode is reorganized into three readable zones: hero card, backpack, and shop/synergies.
- The selected hero card shows a larger portrait and runtime stats.
- Character sprites are normalized to a consistent battle height and action presentation keeps the readable body sprite on screen while runtime VFX handle impacts/spells.
- Idle frames are alpha-trimmed, bottom-anchored, and cleaned to the largest opaque silhouette to remove detached neighboring fragments.
- `Animator.Play` is protected by active-state and `HasState` checks.
- TMP Essential Resources are bootstrapped from the installed Unity UI/TMP package before scene generation.
- Optional Unicode UI glyphs were removed to avoid fallback-font warnings.

## Current playable loop
`Hero Select → Build → Battle → Reward → Run Map → Build → … → Boss → Run Complete`.

Current slice includes:
- four selectable heroes: **Pyromancer, Ice Mage, Poison Assassin, Holy Paladin**;
- encounter roster with Frost Adept, Venom Stalker, Radiant Guardian and Ice Warlord boss;
- 6×5 backpack with Hero Core;
- fifteen Fire/Ice/Poison/Holy items, shop, reroll, fusion and affinity synergies;
- Battle/Elite/Shop/Treasure/Rest/Boss route nodes;
- scaling enemies, rewards, HP/Mana HUD, particles and Save v2 checkpoints.

## Open in Unity
1. Extract to a new empty folder and open with **Unity 6000.6.3f1**.
2. Wait for package resolution and compilation.
3. If the demo was not generated automatically, run **Tools > Backpack Royale > Rebuild > Build Complete Vertical Slice**.
4. Open `Assets/Game/Scenes/BackpackRoyale_Rebuild_Demo.unity`.
5. Run EditMode tests in `Assets/Game/Tests/EditMode`, then enter Play Mode.

## Validation boundary
Container checks:
```bash
python -m pytest tools/tests -q
python tools/validate_rebuild.py
```
The exact v0.1.5 archive was re-extracted and revalidated in the container. Unity compilation/Test Runner/Play Mode still require execution in Unity 6000.6.3f1.

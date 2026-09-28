# BackpackRoyale_Rebuild

Clean rebuild for **Unity 6000.6.3f1**. The old `v0.3.x/v0.4.0` code, Packages, ProjectSettings, scenes, prefabs, asmdefs and DemoBuilder were not copied.

## Preserved visual assets
The approved source-art archive is kept in `Assets/Game/Art`: five character sheets, item/UI atlases, four VFX sheets, backgrounds and concept references. Generated sprites are created from these sources by editor bakers after Unity imports the project.

## Stability-first stack
Built-in Render Pipeline; legacy Input Manager (no `com.unity.inputsystem`); UGUI 2.6.0 + TextMeshPro; SpriteRenderer + Animator; ParticleSystem; ScriptableObjects; Unity Test Framework 1.8.0.

## v0.1.2 playable loop
`Hero Select → Build → Battle → Reward → Run Map → Build → … → Boss → Run Complete`.

Current slice includes:
- Pyromancer vs Ice Barbarian real-time autobattle;
- 6×5 backpack with reserved Hero Core;
- nine items, item icons, shop buying and **1-gold reroll**;
- three Fire synergies and Ember Dagger → Blazing Fang fusion;
- deterministic six-stage run with Battle/Elite route choices and a final Boss;
- enemy HP/damage/armor/attack-speed scaling by stage and route type;
- stage-scaled gold plus **three distinct item reward choices**;
- dedicated world-map screen using the preserved `world_map.png` art;
- HP/Mana bars, battle event feed, arena backdrop, hit flash and damage-type particles;
- sprite-sheet animation baking for five preserved character sheets;
- Save v1 data model and EditMode tests;
- source guards for malformed C# literals, braces, preprocessor balance and forbidden legacy APIs.

## Open in Unity
1. Extract to a new empty folder and open with **Unity 6000.6.3f1**.
2. Wait for package resolution and compilation.
3. If the demo was not generated automatically, run **Tools > Backpack Royale > Rebuild > Build Complete Vertical Slice**.
4. Open `Assets/Game/Scenes/BackpackRoyale_Rebuild_Demo.unity`.
5. Run EditMode tests in `Assets/Game/Tests/EditMode`, then enter Play Mode.

## Validation boundary
Container-side checks:

```bash
python -m pytest tools/tests -q
python tools/validate_rebuild.py
```

This environment does **not** contain Unity Editor. Unity compilation, Unity Test Runner, Play Mode and Windows player build are therefore not claimed until this exact version is opened in Unity 6000.6.3f1.

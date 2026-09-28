# BackpackRoyale_Rebuild

Clean rebuild for **Unity 6000.6.3f1**. This is a new codebase; the old `v0.3.x/v0.4.0` code, Packages, ProjectSettings, scenes, prefabs, asmdefs and DemoBuilder were not copied.

## Preserved visual assets
The approved source-art archive is kept in `Assets/Game/Art`: five character sheets, item/UI atlases, four VFX sheets, backgrounds and concept references. Generated sprites are created from these sources by editor bakers after Unity imports the project.

## Stability-first stack
Built-in Render Pipeline; legacy Input Manager (no `com.unity.inputsystem`); UGUI 2.6.0 + TextMeshPro; SpriteRenderer + Animator; ParticleSystem; ScriptableObjects; Unity Test Framework 1.8.0.

## v0.1.1 vertical slice
`Hero Select → Build → Battle → Reward → Build`.

Current slice includes:
- Pyromancer vs Ice Barbarian real-time autobattle;
- 6×5 backpack with reserved Hero Core;
- nine item definitions, item icons baked from the approved item sheet and rarity presentation;
- shop buying plus **1-gold reroll**;
- three Fire synergies and Ember Dagger → Blazing Fang fusion;
- reward gold plus an optional item claim after victory;
- HP/Mana bars, battle event feed, arena backdrop, hit flash and damage-type particle bursts;
- sprite-sheet animation baking for five preserved character sheets;
- Save v1 data model and EditMode tests;
- source-level guards for malformed C# string/char literals, braces, preprocessor balance and forbidden legacy APIs.

## Open in Unity
1. Extract to a new empty folder and open with **Unity 6000.6.3f1**.
2. Wait for package resolution and compilation.
3. If the demo was not generated automatically, run **Tools > Backpack Royale > Rebuild > Build Complete Vertical Slice**.
4. Open `Assets/Game/Scenes/BackpackRoyale_Rebuild_Demo.unity`.
5. Run EditMode tests in `Assets/Game/Tests/EditMode`, then enter Play Mode.

## Validation boundary
Container-side structural tests and asset checks can be run with:

```bash
python -m pytest tools/tests -q
python tools/validate_rebuild.py
```

This build environment does **not** contain Unity Editor. Unity compilation, Unity Test Runner, Play Mode and Windows player build are therefore not claimed until this exact version is opened in Unity 6000.6.3f1.

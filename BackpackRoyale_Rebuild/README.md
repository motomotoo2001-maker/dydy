# BackpackRoyale_Rebuild

Clean rebuild for **Unity 6000.6.3f1**. This is a new codebase; the old `v0.3.x/v0.4.0` code, Packages, ProjectSettings, scenes, prefabs, asmdefs and DemoBuilder were not copied.

## Preserved visual assets
The approved source-art archive was migrated into `Assets/Game/Art`: five character sheets, UI atlases, four VFX sheets, backgrounds and concept references.

## Stability-first stack
Built-in Render Pipeline; legacy Input Manager (no `com.unity.inputsystem`); UGUI 2.6.0 + TextMeshPro; SpriteRenderer + Animator; ParticleSystem; ScriptableObjects; Unity Test Framework 1.8.0.

## First playable loop
`Hero Select → Build (Shop + 6×5 Backpack + Hero Core + Fusion) → Battle → Reward → Build`.
The slice contains Pyromancer vs Ice Barbarian, nine item definitions, three Fire synergies, Ember Dagger fusion, presentation-independent real-time autobattle, sprite-sheet animation baking and Save v1.

## Open in Unity
1. Extract to a new empty folder and open with **Unity 6000.6.3f1**.
2. Wait for package resolution and compilation.
3. If the demo was not generated automatically, run **Tools > Backpack Royale > Rebuild > Build Complete Vertical Slice**.
4. Open `Assets/Game/Scenes/BackpackRoyale_Rebuild_Demo.unity`.
5. Run EditMode tests in `Assets/Game/Tests/EditMode`, then Play Mode.

## Validation boundary
Container-side structural tests and asset checks can be run with `python -m pytest tools/tests -q` and `python tools/validate_rebuild.py`. The build environment does **not** contain Unity Editor, so Unity compilation, Unity Test Runner results, Play Mode and Windows player build are not claimed until you open this project in Unity 6000.6.3f1.

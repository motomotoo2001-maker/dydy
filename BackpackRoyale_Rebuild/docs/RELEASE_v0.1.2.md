# BackpackRoyale_Rebuild v0.1.2

## Progression update

This checkpoint adds the first real run-progression layer on top of the v0.1.1 vertical slice.

### Gameplay
- deterministic 6-stage run map
- two route choices on stages 2–5: Battle or Elite
- final stage is a single Boss node
- enemy HP/damage/armor/attack-speed scale with stage
- Elite and Boss nodes apply additional difficulty multipliers
- reward generation moved into `RewardService`
- victory grants stage-scaled gold and three deterministic distinct item choices
- player may claim at most one reward item
- map selection returns to Build before the next battle
- final boss victory enters a Run Complete state and allows a new run

### Presentation
- `world_map.png` is used as the run-map backdrop
- dedicated `RunMapPanel` with route buttons
- reward panel expanded to three item choices
- reward button labels reset correctly between victory, defeat and new-run states

### Architecture
- added `RunNode`, `RunMapState`, `RunMapService`
- added `EnemyScalingService`
- added `RewardOffer`, `RewardService`
- added `RunMapView`
- battle runtime accepts externally scaled enemy `CombatStats`
- ScriptableObjects remain configuration-only; run state stays in runtime objects

### Validation boundary
Container-side checks validate source structure, package constraints, basic C# delimiter/literal safety, and release contents. The environment does not contain Unity Editor, so Unity compilation, EditMode/PlayMode Test Runner results and Windows build are not claimed until the project is opened in Unity 6000.6.3f1.

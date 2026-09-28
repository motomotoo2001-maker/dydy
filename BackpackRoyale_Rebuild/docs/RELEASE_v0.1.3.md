# BackpackRoyale_Rebuild v0.1.3

## Roster & encounter update

This checkpoint turns the single-character/single-enemy prototype into a small real roster while preserving the stability-first architecture.

### Playable heroes
- Pyromancer — Fire/Burn, balanced caster
- Ice Mage — Ice/Freeze, control caster
- Poison Assassin — Poison/DoT, high attack speed
- Holy Paladin — Holy damage, high durability

All four use the preserved approved character sheets and the existing animation baker.

### Encounter roster
- Frost Adept (`ice_mage` visual)
- Venom Stalker (`poison_assassin` visual)
- Radiant Guardian (`holy_paladin` visual)
- Ice Warlord (`ice_barbarian` visual), reserved as the Boss encounter

`EncounterService` chooses regular/elite encounters deterministically from the run seed and stage. Boss nodes always select the reserved final enemy.

### Runtime presentation
`CharacterView` now receives a preloaded visual library containing IDs, `RuntimeAnimatorController` references and idle Sprites. `UseVisual(id)` switches playable/enemy presentation at runtime without editor-only APIs.

### Data model
`RebuildContentDatabase` now stores hero/enemy arrays and exposes `Heroes`, `Enemies`, `FindHero` and `FindEnemy`. Legacy single hero/enemy fields remain as a safe fallback until the content factory rebuilds older generated assets.

### Validation
- 20/20 container contract tests passed on the packaged checkpoint.
- Static validator found 62 C# files and 18 PNG assets and returned `VALIDATION_OK`.
- ZIP integrity check reported no errors and no forbidden cache/build directories.

Unity Editor is not installed in the container, so Unity compilation, Test Runner and Play Mode remain pending local verification in Unity 6000.6.3f1.

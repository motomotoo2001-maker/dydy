# BackpackRoyale_Rebuild v0.1.4

Target: Unity 6000.6.3f1, Built-in Render Pipeline.

## Gameplay additions
- Added six affinity items for Ice, Poison and Holy builds: Frost Wand, Glacier Charm, Venom Dagger, Toxic Vial, Radiant Mace and Sun Sigil.
- Expanded `SynergyResolver` with Fire, Ice, Poison and Holy affinity rules plus Hero Core adjacency bonuses.
- Run map now mixes combat routes with Merchant Camp, Treasure Cache and Sacred Rest event nodes.
- Non-combat nodes resolve through `RunEventService`: Shop grants a travel stipend, Treasure grants stage-scaled gold, and Rest grants persistent max-health for the current run.
- Build screen primary action changes to `CONTINUE` on non-combat nodes.

## Save v2
- Added `SaveDataV2` with selected hero, current node, resolved-node state, completed node IDs, persistent run-health bonus and inventory positions/rotations.
- `GameFlow` writes checkpoints through `SaveService.SaveV2` and restores stable Build/RunMap checkpoints through `TryLoadV2`.
- Event-resolution state is stored separately from completion so reloading a Shop/Treasure/Rest node neither duplicates its reward nor skips the node.

## Validation
- Container contract tests: 26/26 passing.
- Source guard subset: 3/3 passing.
- `tools/validate_rebuild.py`: VALIDATION_OK.
- Full ZIP integrity: OK, then the archive was unpacked and revalidated with 26/26 tests.
- Unity Editor compilation / Test Runner / Play Mode still requires opening this exact project in Unity 6000.6.3f1.

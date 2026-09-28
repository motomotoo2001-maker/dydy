# BackpackRoyale_Rebuild v0.1.1

Second clean-rebuild checkpoint for **Unity 6000.6.3f1**.

## Stability fixes
- Fixed malformed C# regular string literals in Backpack/Shop UI source.
- Fixed invalid backslash char literals in all editor folder-normalization helpers.
- Added source gates for malformed string/char literals and unbalanced braces.

## Visual polish
- Added `RebuildVisualBaker` for item/UI sprites generated from approved source atlases.
- Added nine item icons, selected-slot presentation and Hero Core marker.
- Added shop icons and rarity text.
- Added hero/build/battle backdrops; battle uses the volcanic arena crop.
- Added HP/Mana bars, battle event feed, hit flash and damage-type particle bursts.
- Character actions return to Idle instead of sticking on attack/cast frames.

## Gameplay loop improvements
- Shop reroll costs 1 gold.
- Victory rewards +5 gold plus one optional item claim when backpack space is available.
- Battle action events carry `DamageType` and `Ultimate` metadata without coupling combat runtime to VFX.

## Container verification
- 11/11 rebuild contract tests passed.
- Validator: 52 C# files, 18 preserved PNG assets, `VALIDATION_OK`.
- Full ZIP SHA-256: `a95cfb2bbe7e7aaf449b7acde3a76b9c3e3f0a43d31f19df6366686883895110`.

Unity compilation/Play Mode are not claimed because Unity Editor is not present in this build environment.

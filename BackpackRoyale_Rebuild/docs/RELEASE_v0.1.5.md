# BackpackRoyale_Rebuild v0.1.5

Unity target: **6000.6.3f1**

## Visual cleanup
- Replaced mockup-heavy Build and Hero Select backdrops with clean generated arena quadrants.
- Rebuilt Build screen into hero / backpack / shop-synergy columns.
- Added selected-hero portrait and stat card.
- Increased battle character readability with normalized target world height.
- Added safe procedural action poses so large spell/projectile source frames no longer obscure the character.
- Added alpha trim + bottom-center pivot + largest-island cleanup for Idle frames.

## Warning/error cleanup
- Guarded inactive Animator calls and missing states.
- Added automatic TMP Essential Resources bootstrap from the installed Unity UI/TMP package.
- Removed optional Unicode symbols from runtime UI strings.

## Verification
The exact full ZIP was unpacked and checked again after packaging: **37/37 container tests**, `VALIDATION_OK`, ZIP integrity OK, and no Library/Temp/Logs/obj/UserSettings/.git/.vs/.pytest_cache entries in the archive.

Unity Editor compile, EditMode Test Runner, Play Mode and Windows build still need execution on the exact v0.1.5 archive in Unity 6000.6.3f1.

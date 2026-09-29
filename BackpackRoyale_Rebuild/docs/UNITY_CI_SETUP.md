# Unity CI one-time setup

The `backpackroyale-rebuild` branch contains `.github/workflows/unity-ci.yml` for Unity **6000.6.3f1**.

The workflow already verifies and reconstructs the exact v0.1.4 source bundle before Unity starts.

## GitHub repository secrets

Open the repository on GitHub, then:

`Settings → Secrets and variables → Actions → New repository secret`

### Unity Personal
Create these repository secrets:

- `UNITY_EMAIL` — email used for the Unity account
- `UNITY_PASSWORD` — Unity account password
- `UNITY_LICENSE` — complete contents of the activated `.ulf` license file

Do not commit these values to the repository.

### Unity Pro / paid serial license
Create:

- `UNITY_EMAIL`
- `UNITY_PASSWORD`
- `UNITY_SERIAL`

Do not also use the Personal license flow for a Pro license.

## Windows license file

For a serial-based Unity license, Unity documents the Windows license location as:

`%PROGRAMDATA%\Unity\Unity_lic.ulf`

If Windows UAC virtualized the folder, also check:

`%LOCALAPPDATA%\VirtualStore\ProgramData\Unity`

Open the `.ulf` as text and copy the complete contents into the `UNITY_LICENSE` secret when using the Personal-license GameCI flow.

## After adding secrets

Re-run the latest `Unity CI - BackpackRoyale Rebuild` Actions run or push a new commit to `backpackroyale-rebuild`.

Expected pipeline:

1. Verify source-bundle part count and SHA-256.
2. Verify Unity project version 6000.6.3f1.
3. Activate Unity using repository secrets.
4. Import/compile the project and run EditMode tests.
5. Only if EditMode succeeds, run PlayMode tests.
6. Upload Unity test artifacts and logs.

Never paste Unity passwords, serials, or license contents into issues, commits, or chat messages.

# Unity CI source bundle — v0.1.4

This directory stores the verified source-only Unity project bundle as ordered Base64 chunks so GitHub Actions can reconstruct it without depending on Google Drive.

- Bundle: `BackpackRoyale_Rebuild_Source_v0.1.4.zip`
- Parts: `part-000.b64` … `part-012.b64`
- SHA-256: `7587ccac89482f6a01ade88db6ee449f58d57e0f1a008030dedfcb4803739da5`
- Unity: `6000.6.3f1`

Reconstruction:

```bash
cat part-*.b64 | base64 --decode > BackpackRoyale_Rebuild_Source_v0.1.4.zip
echo "7587ccac89482f6a01ade88db6ee449f58d57e0f1a008030dedfcb4803739da5  BackpackRoyale_Rebuild_Source_v0.1.4.zip" | sha256sum -c -
```

The workflow validates this hash before Unity is started.

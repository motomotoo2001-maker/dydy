#!/usr/bin/env python3
import json
from pathlib import Path
import sys
import trimesh

ROOT=Path(__file__).resolve().parents[1]
MODELS=ROOT/"assets"/"models"
CONTRACTS=ROOT/"assets"/"concepts"/"character_asset_contracts.json"

def main():
    data=json.loads(CONTRACTS.read_text(encoding="utf-8"))
    failures=[]
    print("ASSET_CONTRACT_VERSION", data.get("version"))
    for filename,cfg in data["assets"].items():
        path=MODELS/filename
        if not path.exists():
            failures.append(f"{filename}: missing file")
            continue
        scene=trimesh.load(path, force="scene", process=False)
        names=set(scene.geometry.keys())
        missing=[x for x in cfg["required_parts"] if x not in names]
        if len(names) < int(cfg["min_parts"]):
            failures.append(f"{filename}: only {len(names)} parts, expected >= {cfg['min_parts']}")
        if missing:
            failures.append(f"{filename}: missing parts {missing}")
        materials=set()
        for mesh in scene.geometry.values():
            mat=getattr(getattr(mesh,"visual",None),"material",None)
            name=getattr(mat,"name",None)
            if name:
                materials.add(name)
        if len(materials) < 4:
            failures.append(f"{filename}: only {len(materials)} material groups")
        print(f"ASSET_CONTRACT_OK {filename} parts={len(names)} materials={len(materials)}")
    if failures:
        for f in failures:
            print("ASSET_CONTRACT_FAIL",f)
        return 2
    print("ASSET_CONTRACTS_PASS",len(data["assets"]))
    return 0

if __name__=="__main__":
    sys.exit(main())

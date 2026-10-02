import json
import os
import sys

def check_manifest():
    manifest_path = "assets/MANIFEST.3d.json"
    if not os.path.exists(manifest_path):
        print(f"Error: {manifest_path} not found.")
        sys.exit(1)

    with open(manifest_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    assets = data.get("assets", [])
    required_fields = ["id", "kind", "path", "source", "tool", "prompt", "seed", "date", "license_note", "used_by"]
    valid_kinds = ["model", "portrait", "texture", "ui", "video", "anim"]
    valid_sources = ["placeholder", "ai", "hand"]

    errors = 0

    for idx, asset in enumerate(assets):
        for field in required_fields:
            if field not in asset:
                print(f"Error in asset {asset.get('id', idx)}: missing field '{field}'")
                errors += 1
        
        kind = asset.get("kind")
        if kind and kind not in valid_kinds:
            print(f"Error in asset {asset.get('id', idx)}: invalid kind '{kind}'")
            errors += 1
            
        source = asset.get("source")
        if source and source not in valid_sources:
            print(f"Error in asset {asset.get('id', idx)}: invalid source '{source}'")
            errors += 1
            
        path = asset.get("path")
        if path and not os.path.exists(path):
            print(f"Error in asset {asset.get('id', idx)}: path '{path}' does not exist.")
            errors += 1

    if errors == 0:
        print("Manifest is valid.")
        sys.exit(0)
    else:
        print(f"Manifest validation failed with {errors} errors.")
        sys.exit(1)

if __name__ == "__main__":
    check_manifest()

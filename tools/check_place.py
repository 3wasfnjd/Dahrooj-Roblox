"""Structural check of the built Dahrooj.rbxlx: every src script exists in the right place with its source."""
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASES = {
    "shared": ["ReplicatedStorage", "Shared"],
    "server": ["ServerScriptService", "Server"],
    "client": ["StarterPlayer", "StarterPlayerScripts", "Client"],
}


def name_of(i):
    return i.findtext("Properties/string[@name='Name']")


def main(path):
    root = ET.parse(path).getroot()
    services = {i.get("class"): i for i in root.findall("Item")}
    errors = []
    for top, base in BASES.items():
        for f in sorted((ROOT / "src" / top).rglob("*.luau")):
            rel = f.relative_to(ROOT / "src" / top)
            stem = f.name.split(".")[0]
            cls = "Script" if f.name.endswith(".server.luau") else "LocalScript" if f.name.endswith(".client.luau") else "ModuleScript"
            node = services.get(base[0])
            for name in base[1:] + list(rel.parent.parts) + [stem]:
                node = next((c for c in node.findall("Item") if name_of(c) == name), None) if node is not None else None
            label = "/".join(base + list(rel.parent.parts) + [stem])
            if node is None or node.get("class") != cls:
                errors.append(f"missing {cls} {label}")
                continue
            src = node.findtext("Properties/ProtectedString[@name='Source']") or ""
            if src.strip() != f.read_text(encoding="utf-8").strip():
                errors.append(f"source mismatch {label}")
            else:
                print(f"ok   {cls:12s} {label}")
    lighting = services.get("Lighting")
    clock = lighting.find("Properties/float[@name='ClockTime']") if lighting is not None else None
    print("ok   Lighting daytime" if clock is not None and float(clock.text) > 6 else "")
    if errors:
        print("\nFAILED:\n  - " + "\n  - ".join(errors))
        for e in errors[:10]:
            print("::error::" + e)
        sys.exit(1)
    print("\nPlace file structure OK")


if __name__ == "__main__":
    main(sys.argv[1])

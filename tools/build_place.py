"""Build Dahrooj.rbxlx from src/ without Rojo (same layout as default.project.json).

usage: python3 tools/build_place.py [--out Dahrooj.rbxlx]
"""
import argparse
import itertools
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
_ref = itertools.count(1)


def item(parent, cls, name):
    it = ET.SubElement(parent, "Item", {"class": cls, "referent": f"RBX{next(_ref):08X}"})
    props = ET.SubElement(it, "Properties")
    ET.SubElement(props, "string", {"name": "Name"}).text = name
    return it


def script(parent, path: Path):
    n = path.name
    if n.endswith(".server.luau"):
        cls, name = "Script", n[: -len(".server.luau")]
    elif n.endswith(".client.luau"):
        cls, name = "LocalScript", n[: -len(".client.luau")]
    else:
        cls, name = "ModuleScript", n[: -len(".luau")]
    it = item(parent, cls, name)
    ET.SubElement(it.find("Properties"), "ProtectedString", {"name": "Source"}).text = path.read_text(encoding="utf-8")


def folder_tree(parent, directory: Path, name: str):
    f = item(parent, "Folder", name)
    for p in sorted(directory.iterdir()):
        if p.is_dir():
            folder_tree(f, p, p.name)
        elif p.suffix == ".luau":
            script(f, p)
    return f


def color(props, name, rgb):
    c = ET.SubElement(props, "Color3", {"name": name})
    for k, v in zip("RGB", rgb):
        ET.SubElement(c, k).text = str(v)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ROOT / "Dahrooj.rbxlx"))
    a = ap.parse_args()
    root = ET.Element("roblox", {"version": "4"})
    ws = item(root, "Workspace", "Workspace")
    lighting = item(root, "Lighting", "Lighting")
    lp = lighting.find("Properties")
    ET.SubElement(lp, "float", {"name": "ClockTime"}).text = "14.5"
    ET.SubElement(lp, "float", {"name": "Brightness"}).text = "2.4"
    ET.SubElement(lp, "bool", {"name": "GlobalShadows"}).text = "true"
    color(lp, "Ambient", (0.45, 0.42, 0.48))
    color(lp, "OutdoorAmbient", (0.55, 0.52, 0.58))
    rs = item(root, "ReplicatedStorage", "ReplicatedStorage")
    folder_tree(rs, ROOT / "src/shared", "Shared")
    sss = item(root, "ServerScriptService", "ServerScriptService")
    folder_tree(sss, ROOT / "src/server", "Server")
    sp = item(root, "StarterPlayer", "StarterPlayer")
    sps = item(sp, "StarterPlayerScripts", "StarterPlayerScripts")
    folder_tree(sps, ROOT / "src/client", "Client")
    for cls in ("Players", "StarterGui", "SoundService"):
        item(root, cls, cls)
    ET.ElementTree(root).write(a.out, encoding="utf-8", xml_declaration=True)
    print("wrote", a.out)


if __name__ == "__main__":
    main()

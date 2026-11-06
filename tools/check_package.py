"""Reject misnested, incomplete, or developer-file-contaminated release ZIPs."""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
import zipfile

from lupa.lua51 import LuaRuntime


def check(path):
    expected = {
        "PetPantry/Bindings.xml", "PetPantry/CHANGELOG.md", "PetPantry/LICENSE.txt",
        "PetPantry/PetPantry.lua", "PetPantry/PetPantry.toc",
        "PetPantry/Locales/enUS.lua", "PetPantry/Locales/deDE.lua",
        "PetPantry/TRANSLATING.md",
        "PetPantry/Sounds/crunch.ogg", "PetPantry/Sounds/fanfare.ogg", "PetPantry/Sounds/whimper.ogg",
    }
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None, "ZIP checksum failure"
        files = {name for name in archive.namelist() if not name.endswith("/")}
        assert files == expected, f"Unexpected ZIP contents: {files ^ expected}"
        toc = archive.read("PetPantry/PetPantry.toc").decode("utf-8-sig")
        assert "## Interface: 16001" in toc, "Wrong WoW flavor/interface"
        assert "## X-Curse-Project-ID: 1720041" in toc, "Wrong CurseForge project"
        for line in toc.splitlines():
            if line.strip() and not line.startswith("#"):
                assert "PetPantry/" + line.strip().replace("\\", "/") in files
        ET.fromstring(archive.read("PetPantry/Bindings.xml"))
        for name in files:
            if name.endswith(".lua"):
                LuaRuntime().execute("assert(loadstring(...))", archive.read(name).decode("utf-8-sig"))
        for name in files:
            if name.endswith(".ogg"):
                assert archive.read(name).startswith(b"OggS"), f"Invalid sound: {name}"
    print(f"PASS: {path.name}: folder layout, files, TOC, Lua, XML, sounds")


if __name__ == "__main__":
    packages = list(Path(sys.argv[1]).glob("*.zip"))
    assert packages, "No release ZIP produced"
    for package in packages:
        check(package)

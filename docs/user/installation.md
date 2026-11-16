# Installation

nyx-bridge-maya is installed as a **Maya module**: a folder with the Python package and
the plug-in, found through a `.mod` file in Maya's module path. The package and its
dependency (`sowwic-nyx-bridge`) live in the module, so nothing is installed into Maya's
own Python.

## Requirements

- Maya 2026 or another Maya with Python 3.11 to 3.13.
- [uv](https://docs.astral.sh/uv/) and `make`, to build the module from source.

## 1. Tell the build where Maya is

Create a `.env` file in the project root (or `~/.config/maya-ci.env`):

```sh
MAYAPY=/Applications/Autodesk/maya2026/Maya.app/Contents/bin/mayapy
MAYA_MODULE_PATH=~/Library/Preferences/Autodesk/maya/modules
```

| Variable | Meaning |
| --- | --- |
| `MAYAPY` | The `mayapy` of the Maya you use. Only needed for tests and `make venv`. |
| `MAYA_MODULE_PATH` | Folder the `.mod` file is copied to. With several folders separated by `:` the first one is used. |

Typical module folders:

| Platform | Folder |
| --- | --- |
| macOS | `~/Library/Preferences/Autodesk/maya/modules` |
| Windows | `%USERPROFILE%\Documents\maya\modules` |
| Linux | `~/maya/modules` |

The file is looked up in this order: `MAYA_CI_ENV_FILE`, `./.env`, `~/.config/maya-ci.env`.

## 2. Install

```sh
make install
```

This runs two steps you can also run alone:

| Target | What it does |
| --- | --- |
| `make dist` | Assembles `dist/nyx_bridge_maya_module/` with `python/` (the package and its dependencies) and `plug-ins/`. |
| `make install-module` | Writes `dist/nyx_bridge_maya.mod` from `templates/nyx_bridge_maya.mod` and copies it to `MAYA_MODULE_PATH`. |

The installed `.mod` file points at the `dist/` folder of your checkout, so keep the
checkout in place, and run `make install` again after pulling changes.

To remove it: `make uninstall`.

## 3. Check it in Maya

Restart Maya, then in the Script Editor:

```python
import maya.cmds as cmds

cmds.loadPlugin("nyx_bridge_maya_plugin")
import nyx_bridge_maya
print(nyx_bridge_maya.__version__)
```

To load the plug-in on every start, tick **Auto Load** for `nyx_bridge_maya_plugin.py` in
**Windows > Settings/Preferences > Plug-in Manager**.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| `Plug-in, "nyx_bridge_maya_plugin", was not found` | The `.mod` file is not in a folder of `MAYA_MODULE_PATH` as Maya sees it. `cmds.moduleInfo(listModules=True)` should list `nyx_bridge_maya`. |
| `No module named nyx_bridge_maya` | The module is found but `python/` is empty: run `make dist` and look for errors. |
| `make install` says `Set MAYA_MODULE_PATH in ...` | The env file is missing or does not define it. |
| The `.mod` points at a folder that no longer exists | Run `make install` again from the current checkout. |

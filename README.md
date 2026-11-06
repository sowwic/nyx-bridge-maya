# nyx-bridge-maya

![Tests](https://github.com/sowwic/nyx-bridge-maya/actions/workflows/unit_tests.yml/badge.svg)
![Code Quality](https://github.com/sowwic/nyx-bridge-maya/actions/workflows/code_quality.yml/badge.svg)

Connects Maya to a running [Nyx](https://github.com/sowwic/nyx), so stages can send
commands to Maya and get results back. Maya connects out to Nyx's bridge server; Nyx
never launches or reaches into Maya on its own.

## Use

`make install` builds the Maya module and installs its `.mod` file. Then in Maya:

```python
import maya.cmds as cmds

cmds.loadPlugin("nyx_bridge_maya_plugin")
cmds.nyxBridge(start=True)                      # connect, retrying until Nyx is up
cmds.nyxBridge(query=True, connected=True)      # [True] once Nyx accepted Maya
cmds.nyxBridge(stop=True)
```

Or without the plug-in, from Python:

```python
import nyx_bridge_maya

nyx_bridge_maya.start()                         # background thread, returns the client
nyx_bridge_maya.is_connected()
nyx_bridge_maya.stop()
```

Nyx is found through the address file it writes, so on the same machine no setup is
needed. Otherwise pass `address="host:port"` and `token=...` (flags `-address`,
`-token`, `-name` on the command) or set `NYX_BRIDGE_ADDRESS` and `NYX_BRIDGE_TOKEN`.
What Nyx sends runs on Maya's main thread; scripts find `cmds`, `mel` and `om`
(`maya.api.OpenMaya`) in their namespace. In `mayapy` use
`nyx_bridge_maya.MayaClient().serve_forever()` instead, there is no event loop for
`start` to hand work to.

## Development

```sh
uv sync            # install the project and dev dependencies
make check         # lint + tests
make help          # list all targets
```

### Maya

Tests run inside `mayapy` (`./mayapy_test.sh`, used by `make pytest`). Create a `.env` file
(git-ignored) in the project root, or `~/.config/maya-ci.env`:

```sh
MAYAPY=/Applications/Autodesk/maya2026/Maya.app/Contents/bin/mayapy
MAYA_MODULE_PATH=~/Library/Preferences/Autodesk/maya/modules
```

Set `python_version` to the Python version bundled with your Maya (`make venv` recreates
`.venv` with it). CI runs on a self-hosted runner; trigger it with `make dispatch-pytest`.
`make install` builds and installs the Maya module.

## Releasing

1. Add a `v<version>` entry to `CHANGELOG.rst`, update `VERSION` (`make update-version`) and commit on `main`.
2. `make release VERSION=<version>` tags, pushes (triggering the GitHub release workflow) and back-merges into `develop`.

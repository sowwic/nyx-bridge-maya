# Developer Guide

This guide is for people who work on nyx-bridge-maya itself.

## Setup

```bash
uv sync
make check        # ruff + pytest in mayapy
make mkdocs       # serve these docs
```

`make help` lists every target. Ruff uses a line length of 89 and the `E`, `F` and `UP`
rules. Docstrings are Google style: the API reference is generated from them.

Tests need a Maya: see [Testing](testing.md) for the `.env` file and how they run.

!!! important
    `import nyx_bridge_maya` must work **outside Maya** (docs, tooling), so `maya.*`
    modules are imported inside the methods that use them. Only `command.py` and the
    plug-in import `maya.api.OpenMaya` at the top, since Maya is the only one loading them.

## Pages

| Page | What you learn |
| --- | --- |
| [Architecture](architecture.md) | The package, the plug-in, threads and the main-thread hand-off. |
| [Testing](testing.md) | `mayapy_test.sh`, the environment file, the test layout and CI. |
| [Releasing](releasing.md) | Versions, the changelog and `make release`. |
| API reference | Generated from the docstrings (see the navigation). |

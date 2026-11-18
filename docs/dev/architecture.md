# Architecture

```text
src
├── nyx_bridge_maya
│   ├── client.py    MayaClient, start/stop/is_*, serve_standalone
│   ├── command.py   the nyxBridge MPxCommand
│   └── version.py   __version__
└── plug-ins
    └── nyx_bridge_maya_plugin.py   registers the command
templates/nyx_bridge_maya.mod       module file, filled in by `make maya-module-file`
```

`MayaClient` is a subclass of `nyx_bridge.client.NyxClient`; see
[Writing a client](https://sowwic.github.io/nyx-bridge/dev/clients/) for what each hook is.

| Member | Maya specific |
| --- | --- |
| `CLIENT_KIND` | `"maya"` |
| `client_version()` | `cmds.about(version=True)` |
| `default_namespace()` | `cmds`, `mel`, `om` (`maya.api.OpenMaya`) |
| `run_on_main_thread(func)` | Runs `func` directly on the main thread, else `maya.utils.executeInMainThreadWithResult`. |

## Two ways to serve

- **Interactive Maya**: `start()` uses `start_in_thread()`. The reading loop lives on a
  daemon thread, and every execution is handed to Maya's main thread through
  `executeInMainThreadWithResult`, which needs Maya's event loop.
- **`mayapy`**: there is no event loop, so handing work over would wait forever.
  `serve_standalone()` serves from the main thread with `serve_forever()`, where
  `run_on_main_thread` calls `func` straight away. `reconnect=False`, since the process is
  started for one stage.

## Module state

`client.py` keeps one client and its thread in module globals. `start()` returns the
running one, `stop()` clears them and joins the thread (5 s). The plug-in's
`uninitializePlugin` calls `stop()`, so unloading never leaves a connection behind.

## The command

`NyxBridgeCommand` (`command.py`) is a thin layer over those functions, written for the
Python API 2.0 (`maya_useNewAPI` in the plug-in). `-stop` is handled before `-start`, so
both together restart the client. Queries use `setResult`, which Maya returns as a list.

## The module

`make dist` installs the package from the project folder into
`dist/nyx_bridge_maya_module/python` (so dependencies that are git sources in
`[tool.uv.sources]` resolve) and copies `src/plug-ins` next to it. The `.mod` template
has `@VERSION@` and `@MODULE_ROOT@` filled in by sed. The targets come from
[sowwic/makefiles](https://github.com/sowwic/makefiles) (`dcc/maya`), fetched into `.make/`
and committed; `make update-make` fetches them again.

`DIST_EXTRAS` (space or comma separated, empty by default) installs optional dependencies
of the package into the module as well: `make dist DIST_EXTRAS=usd` runs
`uv pip install --target ... ".[usd]"`. The extras are declared in
`[project.optional-dependencies]` of `pyproject.toml`; today there is `usd`
(`sowwic-nyx-usd`).

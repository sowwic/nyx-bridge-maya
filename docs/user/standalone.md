# Starting Maya from a stage

A stage can start a headless Maya itself, wait for it to connect and run its Remote
Actions in it. Use a **Launch Process** node around a **Remote Client**:

```text
Launch Process  ->  Remote Client  ->  Remote Action ...
```

Settings of the Launch Process node:

| Input | Value |
| --- | --- |
| `command` | `"$MAYAPY" -c "import maya.standalone; maya.standalone.initialize(name='python'); import nyx_bridge_maya; nyx_bridge_maya.serve_standalone(); maya.standalone.uninitialize()"` |
| `env` | `{"MAYAPY": "/Applications/Autodesk/maya2026/Maya.app/Contents/bin/mayapy", "MAYA_MODULE_PATH": "<folder with the nyx_bridge_maya.mod>"}` |
| `timeout` | Seconds to wait for Maya to boot (default 60). |

Nyx gives the process the address and token of its bridge server and the name it is to
connect as (`NYX_BRIDGE_ADDRESS`, `NYX_BRIDGE_TOKEN`, `NYX_BRIDGE_CLIENT_NAME`), which
`serve_standalone` uses. The Remote Client inside the node uses that Maya and no other.

- `MAYA_MODULE_PATH` is only needed when Maya does not find the module itself.
  `make install` puts the `.mod` file in the folder from your `.env`.
- `mayapy` has no event loop, so requests run on the calling thread and `serve_standalone`
  does not reconnect: it returns when Nyx asks Maya to shut down or the connection ends.
- When the nodes inside are done Nyx asks Maya to shut down, and stops the process if it
  does not. The Nyx window waits while Maya boots.

## Using USD in a headless Maya

To run the [nyx-usd](https://github.com/sowwic/nyx-usd) nodes in this Maya, install the
`usd` extra (`make install DIST_EXTRAS=usd`) and add the version of USD Maya should use to
the `env` input:

```json
{
  "MAYAPY": "/Applications/Autodesk/maya2026/Maya.app/Contents/bin/mayapy",
  "MULTI_USD_VERSION": "0.25.5"
}
```

Without `MULTI_USD_VERSION` a USD node fails with `ModuleNotFoundError: No module named
'pxr'`: `mayapy` can't find the USD that comes with Maya. The versions installed are the
`USD_<version>` folders next to the `mayausd.mod` file Maya uses
(`/Users/Shared/Autodesk/modules/maya/2026/` on macOS). If you start Maya from a script,
`unset PYTHONPATH` in it when your shell has a standalone USD there, and export
`MULTI_USD_VERSION` instead.

## Without Nyx starting it

In your own `mayapy` script:

```python
import maya.standalone

maya.standalone.initialize(name="python")

from nyx_bridge_maya import MayaClient

MayaClient().serve_forever()        # blocks; address from the environment or address file
```

`serve_standalone(name, address, token, connect_timeout)` takes the same settings. Give
`connect_timeout` (seconds) to fail with `ConnectionError` instead of waiting forever.

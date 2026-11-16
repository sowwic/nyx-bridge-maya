# Connecting Maya to Nyx

Once the module is [installed](installation.md), Maya connects to Nyx in one of three
ways. All of them start a `MayaClient`, which keeps retrying until Nyx is running, and
connects again if the connection drops.

## The `nyxBridge` command

Provided by the plug-in:

```python
import maya.cmds as cmds

cmds.loadPlugin("nyx_bridge_maya_plugin")
cmds.nyxBridge(start=True)                      # connect, retrying until Nyx is up
cmds.nyxBridge(query=True, connected=True)      # [True] once Nyx accepted Maya
cmds.nyxBridge(query=True, running=True)        # [True] while the client is serving
cmds.nyxBridge(stop=True)
```

| Flag | Short | Meaning |
| --- | --- | --- |
| `-start` | `-s` | Start the client. Does nothing if one is already running. |
| `-stop` | `-x` | Disconnect and stop it. Used together with `-start` it restarts. |
| `-running` | `-r` | Query: the client is serving, connected or not. |
| `-connected` | `-c` | Query: Nyx has accepted Maya. |
| `-address` | `-a` | `host:port` of Nyx. |
| `-token` | `-t` | Token of the Nyx server. |
| `-name` | `-n` | Name Nyx shows for this Maya. |

Maya hands back the result of a Python command as a list, so a query gives `[True]`.
Unloading the plug-in disconnects.

## From Python

Without the plug-in:

```python
import nyx_bridge_maya

nyx_bridge_maya.start()                         # background thread, returns the client
nyx_bridge_maya.is_running()
nyx_bridge_maya.is_connected()                  # plain bool
nyx_bridge_maya.stop()
```

`start(address=None, token=None, name=None)` returns the already running client if there
is one and ignores its arguments then.

## Finding Nyx

Maya looks for the host, port and token in this order:

1. The `address` and `token` arguments (`-address` and `-token` of the command).
2. The environment: `NYX_BRIDGE_ADDRESS` (`host:port`) with `NYX_BRIDGE_TOKEN`.
3. The address file a running Nyx writes.

On the same machine nothing needs to be configured. For Nyx on another machine pass
`address="host:port"` and `token=...`. Details are in
[Finding the server](https://sowwic.github.io/nyx-bridge/user/addresses/).

## What scripts see

What Nyx sends runs on **Maya's main thread**, so `maya.cmds` is safe to use. The
namespace of a connection lives as long as the connection, and starts with:

| Name | Is |
| --- | --- |
| `cmds` | `maya.cmds` |
| `mel` | `maya.mel` |
| `om` | `maya.api.OpenMaya` |

```python
# what a stage sends
result = cmds.polyCube(name="box")[0]
```

Printed output is sent back, an exception comes back as an error of that execution and
Maya keeps working. Executions run one at a time: while a long script runs, Maya's UI is
busy as with any script run in the Script Editor.

## Logging

Connections are logged to `nyx_bridge_maya.client` (and `nyx_bridge.client`) at `INFO`.

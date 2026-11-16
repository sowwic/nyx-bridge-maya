# nyx-bridge-maya

Connects Autodesk Maya to a running [Nyx](https://github.com/sowwic/nyx), so stages can
send commands to Maya and get the results back. It is the Maya client of
[nyx-bridge](https://github.com/sowwic/nyx-bridge): Maya **connects out** to the bridge
server of Nyx, Nyx never launches or reaches into Maya on its own.

```python
# in Maya's Script Editor
import maya.cmds as cmds

cmds.loadPlugin("nyx_bridge_maya_plugin")
cmds.nyxBridge(start=True)        # connects, retrying until Nyx is up
```

```python
# in mayapy
import nyx_bridge_maya

nyx_bridge_maya.MayaClient().serve_forever()
```

| If you want to... | Read |
| --- | --- |
| Install the module and connect Maya to Nyx | [User Guide](user/index.md) |
| Work on nyx-bridge-maya, run its tests in `mayapy` | [Developer Guide](dev/index.md) |
| Look up a class or function | API reference (see the navigation) |

Requires Maya 2026 (Python 3.11) or any Maya whose Python is 3.11 to 3.13. See also
[nyx-bridge-blender](https://github.com/sowwic/nyx-bridge-blender).

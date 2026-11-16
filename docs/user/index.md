# User Guide

This guide is for people who connect Maya to Nyx.

## Pages

| Page | What you learn |
| --- | --- |
| [Installation](installation.md) | Installing the Maya module, the `.mod` file, checking that Maya finds it. |
| [Connecting Maya to Nyx](connecting.md) | The `nyxBridge` command, the Python API, addresses and tokens, what scripts see. |
| [Starting Maya from a stage](standalone.md) | Headless `mayapy` started by a Launch Process node. |

## How it fits together

```text
   Nyx                                       Maya
┌──────────────┐   Maya connects out    ┌───────────────────┐
│ BridgeServer │ ◀───────────────────── │ MayaClient        │
│              │ ───── execute ───────▶ │ runs on the main  │
│ ClientSession│ ◀──── result ───────── │ thread            │
└──────────────┘                        └───────────────────┘
```

1. Nyx listens on a local port and holds a secret token.
2. Maya starts a `MayaClient` (with the `nyxBridge` command or `nyx_bridge_maya.start()`),
   which keeps trying until Nyx accepts it.
3. Nyx sends code; Maya runs it on its main thread and answers with the value and the
   captured output.

Protocol and server details are in the
[nyx-bridge documentation](https://sowwic.github.io/nyx-bridge/).

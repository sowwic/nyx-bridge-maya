nyx-bridge-maya
===============

v1.0.1
------
* (#7) Add nyx-usd as optional extra via `make install DIST_EXTRAS=usd`

v1.0.0
------
* Implement client serving in batch (#1)
* Add ``MayaClient``, ``nyx_bridge_maya.start``/``stop`` and the ``nyxBridge`` command in the plug-in.
* Add ``serve_standalone`` to serve Nyx from ``mayapy``, for stages that start Maya with a Launch Process node.

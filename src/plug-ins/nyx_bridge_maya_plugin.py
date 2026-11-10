import maya.api.OpenMaya as om

from nyx_bridge_maya import client
from nyx_bridge_maya.command import COMMAND_NAME, NyxBridgeCommand
from nyx_bridge_maya.version import __version__

VENDOR = "Dima Shevchenko"


def maya_useNewAPI():
    """Tell Maya this plug-in uses the Python API 2.0."""


def initializePlugin(plugin):
    """Add the `nyxBridge` command, that connects Maya to Nyx."""
    om.MFnPlugin(plugin, VENDOR, __version__).registerCommand(
        COMMAND_NAME, NyxBridgeCommand.creator, NyxBridgeCommand.create_syntax
    )


def uninitializePlugin(plugin):
    """Disconnect from Nyx and remove the command."""
    client.stop()
    om.MFnPlugin(plugin).deregisterCommand(COMMAND_NAME)

import maya.api.OpenMaya as om


def maya_useNewAPI():
    """Tell Maya this plug-in uses the Python API 2.0."""


def initializePlugin(plugin):
    om.MFnPlugin(plugin, "Dima Shevchenko", "1.0.0")


def uninitializePlugin(plugin):
    om.MFnPlugin(plugin)

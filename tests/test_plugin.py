import time
import pytest
from nyx_bridge.server import BridgeServer

import nyx_bridge_maya

PLUGIN = "nyx_bridge_maya_plugin"


@pytest.fixture
def plugin():
    import maya.cmds as cmds

    cmds.loadPlugin(PLUGIN, quiet=True)
    yield
    nyx_bridge_maya.stop()
    cmds.unloadPlugin(PLUGIN)


@pytest.fixture
def server():
    with BridgeServer(name="test", port=0) as running:
        yield running


def query(flag):
    """Value of a query flag. Maya returns the result of a command as a list."""
    import maya.cmds as cmds

    (value,) = cmds.nyxBridge(query=True, **{flag: True})
    return value


def wait_until(predicate, timeout=15):
    deadline = time.monotonic() + timeout
    while not predicate() and time.monotonic() < deadline:
        time.sleep(0.05)
    return predicate()


def test_plugin_adds_the_command_and_removes_it_on_unload():
    import maya.cmds as cmds

    cmds.loadPlugin(PLUGIN, quiet=True)
    assert cmds.pluginInfo(PLUGIN, query=True, command=True) == ["nyxBridge"]

    cmds.unloadPlugin(PLUGIN)
    assert not cmds.pluginInfo(PLUGIN, query=True, loaded=True)


def test_command_starts_and_stops_the_client(plugin, server):
    import maya.cmds as cmds

    assert not query("running")

    cmds.nyxBridge(
        start=True,
        address=f"{server.host}:{server.port}",
        token=server.token,
        name="from-command",
    )

    assert query("running")
    session = server.wait_for_client(name="from-command", kind="maya", timeout=15)
    assert session.kind == "maya"
    assert wait_until(lambda: query("connected"))

    cmds.nyxBridge(stop=True)

    assert not query("running")
    assert wait_until(lambda: not server.clients)


def test_python_api_starts_one_client_and_stops_it(server):
    first = nyx_bridge_maya.start(
        address=(server.host, server.port), token=server.token, name="api"
    )
    try:
        assert nyx_bridge_maya.is_running()
        assert nyx_bridge_maya.get_client() is first
        assert nyx_bridge_maya.start() is first
        server.wait_for_client(name="api", timeout=15)
        assert wait_until(nyx_bridge_maya.is_connected)
    finally:
        nyx_bridge_maya.stop()

    assert not nyx_bridge_maya.is_running()
    assert nyx_bridge_maya.get_client() is None


def test_unloading_the_plugin_disconnects(plugin, server):
    import maya.cmds as cmds

    nyx_bridge_maya.start(
        address=(server.host, server.port), token=server.token, name="unload"
    )
    server.wait_for_client(name="unload", timeout=15)

    cmds.unloadPlugin(PLUGIN)

    assert not nyx_bridge_maya.is_running()
    assert wait_until(lambda: not server.clients)
    cmds.loadPlugin(PLUGIN, quiet=True)  # for the fixture teardown

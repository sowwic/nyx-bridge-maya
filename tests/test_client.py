import threading

import pytest
from nyx_bridge.server import BridgeServer, RemoteExecutionError

from nyx_bridge_maya.client import MayaClient

WAIT = 15


@pytest.fixture
def server():
    with BridgeServer(name="test", port=0) as running:
        yield running


def make_client(server, **kwargs):
    return MayaClient(
        name="maya-test",
        address=(server.host, server.port),
        token=server.token,
        reconnect=False,
        **kwargs,
    )


def run_remote(server, client, *requests):
    """Serve on this (main) thread while another thread sends the requests.

    mayapy has no event loop to hand work to, so like a batch script the client
    serves from the main thread.

    Returns:
        tuple: the client's session on the server, and the result of every request.
    """
    results, errors, sessions = [], [], []

    def send():
        try:
            session = server.wait_for_client(name=client.name, timeout=WAIT)
            sessions.append(session)
            for code, mode in requests:
                results.append(session.execute(code, mode=mode, timeout=WAIT))
        except Exception as err:  # raised on the main thread below
            errors.append(err)
        finally:
            client.stop()

    sender = threading.Thread(target=send)
    sender.start()
    client.serve_forever(connect_timeout=WAIT)
    sender.join(timeout=WAIT)
    if errors:
        raise errors[0]
    return sessions[0], results


def test_client_describes_maya(server):
    client = make_client(server)

    assert client.CLIENT_KIND == "maya"
    assert client.client_version()
    assert {"cmds", "mel", "om"} <= set(client.default_namespace())


def test_server_sees_a_maya_client(server):
    client = make_client(server)

    session, _ = run_remote(server, client)

    assert (session.name, session.kind) == ("maya-test", "maya")
    assert session.version == client.client_version()


def test_scripts_run_maya_commands_and_keep_their_namespace(server):
    import maya.cmds as cmds

    cmds.file(new=True, force=True)
    client = make_client(server)

    _, results = run_remote(
        server,
        client,
        ("cube = cmds.polyCube(name='nyx_cube')[0]\nresult = cube", "exec"),
        ("cmds.objExists(cube)", "eval"),
        ("result = cmds.about(version=True)", "exec"),
    )

    assert [result.value for result in results] == [
        "nyx_cube",
        True,
        client.client_version(),
    ]
    assert cmds.objExists("nyx_cube")


def test_maya_errors_come_back_as_remote_errors(server):
    client = make_client(server)

    with pytest.raises(RemoteExecutionError, match="no_such_command"):
        run_remote(server, client, ("cmds.no_such_command()", "exec"))

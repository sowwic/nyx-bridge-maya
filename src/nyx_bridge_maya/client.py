"""Client connecting a running Maya to Nyx.

Maya's modules are imported when they are needed, so the package can be imported
(by tools, docs) outside of Maya.
"""

from __future__ import annotations

import logging
import threading
import typing

from nyx_bridge.client import NyxClient

LOGGER = logging.getLogger(__name__)


class MayaClient(NyxClient):
    """Nyx client living in Maya.

    What Nyx sends is run on Maya's main thread, so it can use `maya.cmds` safely.
    Scripts find `cmds`, `mel` and `om` (`maya.api.OpenMaya`) in their namespace.

    Serve from a background thread (`start_in_thread`, what `start` does) in an
    interactive Maya. In `mayapy` serve from the main thread with `serve_forever`,
    there is no event loop to hand work over to.
    """

    CLIENT_KIND = "maya"

    def client_version(self) -> str:
        """str: version of Maya."""
        import maya.cmds

        return str(maya.cmds.about(version=True))

    def default_namespace(self) -> dict[str, typing.Any]:
        """Names available to every script run by Nyx.

        Returns:
            dict[str, Any]: `cmds`, `mel` and `om`.
        """
        import maya.api.OpenMaya
        import maya.cmds
        import maya.mel

        return {
            "cmds": maya.cmds,
            "mel": maya.mel,
            "om": maya.api.OpenMaya,
        }

    def run_on_main_thread(self, func: typing.Callable[[], typing.Any]) -> typing.Any:
        """Run a function on Maya's main thread and wait for its result.

        Args:
            func (Callable[[], Any]): function to run.

        Returns:
            Any: whatever the function returns.
        """
        if threading.current_thread() is threading.main_thread():
            return func()

        import maya.utils

        return maya.utils.executeInMainThreadWithResult(func)

    def on_connected(self) -> None:
        """Log that Nyx is connected."""
        LOGGER.info("Connected to Nyx (%s) as %s", self.server_name, self.name)

    def on_disconnected(self) -> None:
        """Log that the connection to Nyx ended."""
        LOGGER.info("Disconnected from Nyx")


_client: MayaClient | None = None
_thread: threading.Thread | None = None


def get_client() -> MayaClient | None:
    """MayaClient | None: the client started by `start`, None if there is none."""
    return _client


def is_running() -> bool:
    """bool: the client started by `start` is serving, connected or not."""
    return _thread is not None and _thread.is_alive()


def is_connected() -> bool:
    """bool: the client started by `start` has a connection to Nyx."""
    return is_running() and _client is not None and _client.is_connected


def start(
    address: str | tuple[str, int] | None = None,
    token: str | None = None,
    name: str | None = None,
) -> MayaClient:
    """Connect Maya to Nyx from a background thread, and keep trying until it works.

    Where Nyx is comes from the arguments, then the environment, then the address file
    Nyx writes, see `nyx_bridge.protocol.find_server_address`. It does not matter
    whether Nyx is already running: the client connects once it is, and again if
    the connection drops.

    Args:
        address (str | tuple[str, int] | None): `host:port` of Nyx.
        token (str | None): token of the Nyx server.
        name (str | None): name Nyx shows for this Maya. Derived from the process id
            if omitted.

    Returns:
        MayaClient: the running client. An already running one is returned as it is,
            the arguments are ignored.
    """
    global _client, _thread
    if is_running():
        return _client
    _client = MayaClient(name=name, address=address, token=token)
    _thread = _client.start_in_thread()
    return _client


def stop() -> None:
    """Disconnect from Nyx and stop the client started by `start`."""
    global _client, _thread
    client, thread = _client, _thread
    _client = _thread = None
    if client is not None:
        client.stop()
    if thread is not None and thread is not threading.current_thread():
        thread.join(timeout=5)

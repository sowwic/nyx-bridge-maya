"""The `nyxBridge` command, registered by the plug-in."""

import maya.api.OpenMaya as om

from nyx_bridge_maya import client

COMMAND_NAME = "nyxBridge"

START_FLAG = ("-s", "-start")
STOP_FLAG = ("-x", "-stop")
RUNNING_FLAG = ("-r", "-running")
CONNECTED_FLAG = ("-c", "-connected")
ADDRESS_FLAG = ("-a", "-address")
TOKEN_FLAG = ("-t", "-token")
NAME_FLAG = ("-n", "-name")


class NyxBridgeCommand(om.MPxCommand):
    """Connect Maya to Nyx, disconnect it, or ask about the connection.

    Python:
        cmds.nyxBridge(start=True)
        cmds.nyxBridge(start=True, address="127.0.0.1:47770", token="...", name="rig")
        cmds.nyxBridge(query=True, connected=True)  # [True] once Nyx accepted Maya
        cmds.nyxBridge(query=True, running=True)
        cmds.nyxBridge(stop=True)

    Maya hands back the result of a Python command as a list, `nyx_bridge_maya.
    is_connected()` and `is_running()` answer with a plain bool.
    """

    @staticmethod
    def creator() -> "NyxBridgeCommand":
        """Create the command, for Maya."""
        return NyxBridgeCommand()

    @staticmethod
    def create_syntax() -> om.MSyntax:
        """Create the syntax of the command, for Maya."""
        syntax = om.MSyntax()
        syntax.enableQuery = True
        for flag in (START_FLAG, STOP_FLAG, RUNNING_FLAG, CONNECTED_FLAG):
            syntax.addFlag(*flag)
        for flag in (ADDRESS_FLAG, TOKEN_FLAG, NAME_FLAG):
            syntax.addFlag(*flag, om.MSyntax.kString)
        return syntax

    def doIt(self, args) -> None:
        """Answer the query, or do what the flags say. Stopping goes before starting,
        so using both restarts the client."""
        parser = om.MArgParser(self.syntax(), args)
        if parser.isQuery:
            self._answer_query(parser)
            return

        if parser.isFlagSet(STOP_FLAG[0]):
            client.stop()
        if parser.isFlagSet(START_FLAG[0]):
            client.start(
                address=self._string_flag(parser, ADDRESS_FLAG),
                token=self._string_flag(parser, TOKEN_FLAG),
                name=self._string_flag(parser, NAME_FLAG),
            )

    def _answer_query(self, parser: om.MArgParser) -> None:
        """Set the result of `-query` with `-running` or `-connected`."""
        if parser.isFlagSet(RUNNING_FLAG[0]):
            self.setResult(client.is_running())
        elif parser.isFlagSet(CONNECTED_FLAG[0]):
            self.setResult(client.is_connected())

    @staticmethod
    def _string_flag(parser: om.MArgParser, flag: tuple[str, str]) -> str | None:
        """str | None: argument of a flag, None if it is not set."""
        if parser.isFlagSet(flag[0]):
            return parser.flagArgumentString(flag[0], 0)
        return None

#!/usr/bin/env bash
set -euo pipefail

# Runs the test suite inside mayapy (maya.standalone).
# The package is installed into a temporary Maya module, so tests exercise the
# same layout Maya loads. Extra arguments are passed to pytest.

# -----------------------------
# Configuration
# -----------------------------
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -n "${MAYA_CI_ENV_FILE:-}" ]]; then
  ENV_FILE="$MAYA_CI_ENV_FILE"
elif [[ -f "$ROOT_DIR/.env" ]]; then
  ENV_FILE="$ROOT_DIR/.env"
else
  ENV_FILE="$HOME/.config/maya-ci.env"
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Maya test configuration was not found."
  echo "Expected one of:"
  echo "  $ROOT_DIR/.env"
  echo "  $HOME/.config/maya-ci.env"
  echo "Or set MAYA_CI_ENV_FILE to an explicit file path."
  exit 1
fi

# MAYAPY should be defined in the env file
set -a
source "$ENV_FILE"
set +a

if [ -z "${MAYAPY:-}" ]; then
  echo "MAYAPY not set. Define it in $ENV_FILE"
  exit 1
fi

echo "Using mayapy: $MAYAPY"

# -----------------------------
#  Build temporary Maya module
# -----------------------------
MODULE_NAME="nyx_bridge_maya"
BUILD_DIR="$ROOT_DIR/build/maya_pytest"
MODULE_ROOT="$BUILD_DIR/${MODULE_NAME}_module"
MODULES_DIR="$BUILD_DIR/modules"
VERSION="$(tr -d '\r\n' <"$ROOT_DIR/VERSION")"

rm -rf "$BUILD_DIR"
mkdir -p "$MODULE_ROOT/python" "$MODULE_ROOT/plug-ins" "$MODULES_DIR"

echo "Installing $MODULE_NAME and test dependencies as a Maya module"
uv pip install \
  --python "$MAYAPY" \
  --target "$MODULE_ROOT/python" \
  --group maya-pytest \
  "$ROOT_DIR"

[ ! -d "$ROOT_DIR/src/plug-ins" ] ||
  cp -R "$ROOT_DIR/src/plug-ins/." "$MODULE_ROOT/plug-ins/"

printf '+ %s %s %s\nPYTHONPATH +:= python\n' \
  "$MODULE_NAME" "$VERSION" "$MODULE_ROOT" >"$MODULES_DIR/$MODULE_NAME.mod"

unset PYTHONPATH
export MAYA_MODULE_PATH="$MODULES_DIR${MAYA_MODULE_PATH:+:$MAYA_MODULE_PATH}"

# -----------------------------
#  Run tests
# -----------------------------
"$MAYAPY" -c '
import sys
import maya.standalone

maya.standalone.initialize(name="python")
try:
    import maya.cmds
    import pytest

    module_path = maya.cmds.moduleInfo(path=True, moduleName=sys.argv[1])
    print(f"Running tests for {sys.argv[1]} module at: {module_path}")
    raise SystemExit(pytest.main(["-vvv", *sys.argv[2:]]))
finally:
    maya.standalone.uninitialize()
' "$MODULE_NAME" "$ROOT_DIR/tests" "$@"

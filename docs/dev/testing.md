# Testing

The tests need Maya's modules, so they run **inside `mayapy`** with `maya.standalone`.

```bash
make pytest                                  # everything, with coverage
./mayapy_test.sh -k plugin                   # extra arguments go to pytest
make pytest-pdb                              # verbose, pdb on failure
```

Do not pass the tests folder or a path to `mayapy_test.sh`: the script always runs
`tests/` itself, and a second spelling of the same path makes pytest refuse its
`conftest.py` twice. Select tests with `-k` instead, e.g. `./mayapy_test.sh -k test_client`.

## Setting up

1. Install Maya (2026 matches the project's `python_version`).
2. Create `.env` in the project root (git-ignored), or `~/.config/maya-ci.env`, or point
   `MAYA_CI_ENV_FILE` at a file:

   ```sh
   MAYAPY=/Applications/Autodesk/maya2026/Maya.app/Contents/bin/mayapy
   MAYA_MODULE_PATH=~/Library/Preferences/Autodesk/maya/modules
   ```

3. Make the virtualenv use the same Python as Maya, so linting and editor tooling agree
   with what the tests run on:

   ```bash
   make venv      # rewrites .python-version from MAYAPY and recreates .venv
   uv sync
   ```

## What `mayapy_test.sh` does

1. Reads the env file and requires `MAYAPY`.
2. Builds a temporary Maya module in `build/maya_pytest/`: installs the package and the
   `maya-pytest` dependency group (`pytest`, `pytest-cov`, `pytest-mock`) into
   `python/`, copies `src/plug-ins`, writes a `.mod` file.
3. Puts that folder on `MAYA_MODULE_PATH` and clears `PYTHONPATH`, so the tests import
   the installed package, **the same layout Maya loads**, not `src/`.
4. Starts `mayapy`, initializes `maya.standalone`, runs `pytest.main` and uninitializes.

Because the package is installed fresh each run, a change in `src/` is picked up without
any extra step. A missing test dependency goes into the `maya-pytest` group of
`pyproject.toml`, not `dev`.

## Layout

| File | Covers |
| --- | --- |
| `tests/test_package.py` | The package imports. |
| `tests/test_client.py` | `MayaClient` against a real `BridgeServer` over loopback: description, namespace, errors, `serve_standalone`. |
| `tests/test_plugin.py` | Loading the plug-in, the `nyxBridge` flags, `start`/`stop`, unloading disconnecting. |

`tests/conftest.py` initializes `maya.standalone` once per session (autouse) and provides
`output_dir`.

## Fixtures and helpers

- `server` (`BridgeServer(port=0)`): the system picks a free port, so tests can run while
  Nyx is open.
- `make_client(server, **kwargs)`: a `MayaClient` pointed at that server with
  `reconnect=False`.
- `run_remote(server, client, *requests)` (`test_client.py`): the client serves on the
  main thread, as in `mayapy`, while another thread sends the requests and collects
  results.
- `wait_until(predicate, timeout=15)` (`test_plugin.py`): poll instead of `sleep`.

## What to cover

- A new `nyxBridge` flag: a test in `test_plugin.py` that loads the plug-in and goes
  through `cmds.nyxBridge`.
- Anything that depends on threads: keep timeouts generous (15 s) and wait on conditions.
  A flaky test here is almost always a missing wait.
- A hook that needs Maya's event loop (`executeInMainThreadWithResult`) can't be
  exercised in `mayapy`; test it with a mock (`pytest-mock`) of `maya.utils`.
- Check in an interactive Maya when a change touches the main-thread hand-off.

## CI

`.github/workflows/unit_tests.yml` calls the shared `maya-tests` workflow on a
**self-hosted runner with Maya installed**; GitHub's hosted runners have no Maya. Its
`.env` lives on the runner. Run it on the current branch with:

```bash
make dispatch-pytest        # needs the gh CLI
```

Lint (`code_quality.yml`) runs on hosted runners and doesn't need Maya: `make lint`.

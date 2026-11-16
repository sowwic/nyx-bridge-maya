# Releasing

## Branches and versions

`develop` is the default and PR branch; `main` is the release branch. Work on a feature
branch named after the GitHub issue (`3-update-nyx-bridge-dependency`).

The version lives in `VERSION`. `make update-version` copies it into `pyproject.toml`.
Add a `v<version>` section at the top of `CHANGELOG.rst`, one bullet per user-visible
change with the issue number where there is one.

nyx-bridge-maya depends on `sowwic-nyx-bridge`. When a new nyx-bridge release is needed,
raise the minimum in `pyproject.toml`, run `uv lock` and add a changelog bullet.

## Release

1. Update `CHANGELOG.rst` and `VERSION` (`make update-version`), commit on `main`.
2. Run

   ```bash
   make release VERSION=1.2.3 [RELEASE_TITLE="..."]
   ```

It tags `main`, pushes and merges back into `develop`. The tag triggers
`.github/workflows/release.yml`, which creates the GitHub release from the changelog
section.

## CI

Workflows in `.github/workflows/` are thin callers of the shared ones in
`sowwic/gh-workflows`: tests (on a self-hosted Maya runner, see [Testing](testing.md#ci)),
lint, docs deployment to GitHub Pages and the release. Dependabot opens update PRs
against `develop`.

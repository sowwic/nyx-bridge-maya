# Autodesk Maya package: tests in mayapy, a .mod module and its install.
#
# Needs PACKAGE_NAME and general/python. Settings (MAYAPY, MAYA_MODULE_PATH) come from an env
# file: MAYA_CI_ENV_FILE, then ./.env, then ~/.config/maya-ci.env.
# Set PYTEST_CMD = ./mayapy_test.sh (the script runs the tests folder by itself).

ENV_FILE ?= $(or $(MAYA_CI_ENV_FILE),$(wildcard .env),$(HOME)/.config/maya-ci.env)
ROOT_DIR := $(CURDIR)
DIST_MODULE_ROOT ?= $(DIST_DIR)/$(PACKAGE_NAME)_module
DIST_MODULE_FILE ?= $(DIST_DIR)/$(PACKAGE_NAME).mod
SOURCE_PLUGINS_DIR ?= src/plug-ins
MODULE_TEMPLATE ?= templates/$(PACKAGE_NAME).mod
TESTS_WORKFLOW ?= unit_tests.yml
GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)

.PHONY: venv
venv: ## Recreate .venv using the Python version of mayapy (MAYAPY from the env file)
	@set -a; . "$(ENV_FILE)"; set +a; \
	: "$${MAYAPY:?Set MAYAPY in $(ENV_FILE)}"; \
	version="$$( "$$MAYAPY" -c 'import sys; print(".".join(map(str, sys.version_info[:3])))' )"; \
	printf '%s\n' "$$version" > .python-version; \
	unset VIRTUAL_ENV; \
	uv venv --clear

.PHONY: dev
dev: venv ## Create venv and enter it
	@. .venv/bin/activate && exec $$SHELL

# The package is installed from the project folder, not from a built wheel: uv then follows
# [tool.uv.sources], so dependencies that only exist as git sources can be installed.
.PHONY: dist
dist: $(BUILD_PREREQS) ## Assemble dist/<package>_module (python + plug-ins)
	@rm -rf $(DIST_MODULE_ROOT)
	@mkdir -p $(DIST_MODULE_ROOT)/python $(DIST_MODULE_ROOT)/plug-ins
	@uv pip install --target $(DIST_MODULE_ROOT)/python .
	@cp -R $(SOURCE_PLUGINS_DIR)/. $(DIST_MODULE_ROOT)/plug-ins/

.PHONY: maya-module-file
maya-module-file: ## Generate dist/<package>.mod
	@mkdir -p "$(DIST_DIR)"
	@sed \
		-e 's|@VERSION@|$(VERSION)|g' \
		-e 's|@MODULE_ROOT@|$(ROOT_DIR)/$(DIST_MODULE_ROOT)|g' \
		"$(MODULE_TEMPLATE)" > "$(DIST_MODULE_FILE)"

.PHONY: install-module
install-module: maya-module-file ## Copy the .mod file to Maya's module directory (MAYA_MODULE_PATH in the env file)
	@set -eu; \
	set -a; . "$(ENV_FILE)"; set +a; \
	: "$${MAYA_MODULE_PATH:?Set MAYA_MODULE_PATH in $(ENV_FILE)}"; \
	module_path="$${MAYA_MODULE_PATH%%:*}"; \
	mkdir -p "$$module_path"; \
	cp "$(DIST_MODULE_FILE)" "$$module_path/$(PACKAGE_NAME).mod"; \
	printf 'Installed %s.mod in %s\n' "$(PACKAGE_NAME)" "$$module_path"

.PHONY: install
install: dist install-module ## Build and install the Maya module

.PHONY: uninstall
uninstall: ## Remove the .mod file from Maya's module directory
	@set -eu; \
	set -a; . "$(ENV_FILE)"; set +a; \
	: "$${MAYA_MODULE_PATH:?Set MAYA_MODULE_PATH in $(ENV_FILE)}"; \
	module_path="$${MAYA_MODULE_PATH%%:*}"; \
	rm -f "$$module_path/$(PACKAGE_NAME).mod"; \
	printf 'Removed %s.mod from %s\n' "$(PACKAGE_NAME)" "$$module_path"

.PHONY: dispatch-pytest
dispatch-pytest: ## Run the tests workflow on the current branch (self-hosted Maya runner)
	gh workflow run $(TESTS_WORKFLOW) --ref $(GIT_BRANCH)

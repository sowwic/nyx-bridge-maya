SHELL := /bin/bash

APP_NAME = nyx-bridge-maya
PACKAGE_NAME = nyx_bridge_maya
VERSION := $(shell tr -d '\r\n' < VERSION)
DIST_DIR = dist
BUILD_DIR = build
MKDOCS_SITE_DIR = site
TEST_OUTPUT_DIR = .test_output
RELEASE_BRANCH ?= main
DEVELOP_BRANCH ?= develop
GH_WORKFLOWS_REF ?= v1
ROOT_DIR := $(CURDIR)
DIST_MODULE_ROOT := $(DIST_DIR)/$(PACKAGE_NAME)_module
DIST_MODULE_FILE := $(DIST_DIR)/$(PACKAGE_NAME).mod
SOURCE_PLUGINS_DIR = src/plug-ins
MODULE_TEMPLATE := templates/$(PACKAGE_NAME).mod
TESTS_WORKFLOW ?= unit_tests.yml
# Same lookup as mayapy_test.sh: explicit file, project .env, then the user config
ENV_FILE ?= $(or $(MAYA_CI_ENV_FILE),$(wildcard .env),$(HOME)/.config/maya-ci.env)
GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)

# Colors
BLUE := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
MAGENTA := \033[35m
CYAN := \033[36m
RESET := \033[0m

# Banner helper
define banner
	@printf "$(CYAN)==>$(RESET) $(1)\n"
endef

.PHONY: help
help: ## Show this help message
	@echo "Available make targets:"
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:.*?##' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS=":.*?##"}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo ""

.PHONY: clean
clean: ## Remove build artifacts, cache, and temporary files
	$(call banner, Cleaning project...)
	@rm -rf .pytest_cache
	@rm -rf .ruff_cache
	@rm -rf __pycache__
	@rm -rf .coverage
	@rm -rf src/**/__pycache__
	@rm -rf tests/**/__pycache__
	@rm -rf $(BUILD_DIR)
	@rm -rf $(DIST_DIR)
	@rm -rf $(TEST_OUTPUT_DIR)
	@rm -rf $(MKDOCS_SITE_DIR)
	@printf "$(GREEN)Clean up complete.$(RESET)\n"

.PHONY: lint
lint: ## Run the Ruff linter on source and test files
	$(call banner, Running Ruff linter...)
	@uv run ruff check src tests

.PHONY: lint-fix
lint-fix: ## Run the Ruff linter on source and test files and apply fixes
	$(call banner, Running Ruff linter with fixes...)
	@uv run ruff check --fix src tests

.PHONY: format
format: ## Run the Ruff formatter on source and test files
	$(call banner, Running Ruff formatter...)
	@uv run ruff format src tests

.PHONY: pytest
pytest: ## Run pytest on tests directory
	$(call banner, Running pytest...)
	@./mayapy_test.sh

.PHONY: pytest-pdb
pytest-pdb: ## Run pytest with pdb on failure
	$(call banner, Cleaning pytest output dir...)
	@rm -rf $(TEST_OUTPUT_DIR)
	$(call banner, Running pytest with pdb...)
	@./mayapy_test.sh --pdb

.PHONY: mkdocs
mkdocs: ## Run MkDocs development server
	$(call banner, Starting MkDocs development server...)
	@uv run mkdocs serve

.PHONY: check
check: lint pytest ## Run all checks (linting and testing)

.PHONY: build
build: ## Build the package using uv
	$(call banner, Building $(APP_NAME)...)
	@uv build

.PHONY: update-version
update-version: ## Update the version in pyproject.toml to match the VERSION file
	$(call banner, Updating version in pyproject.toml...)
	@printf "$(CYAN)==>$(RESET) Updating pyproject.toml version to %s\n" "$(VERSION)"
	@uv version $(VERSION)

.PHONY: release
release: ## Tag, push and back-merge a release: make release VERSION=x.y.z [RELEASE_TITLE=...]
	$(if $(VERSION),,$(error VERSION is required, e.g. make release VERSION=1.2.3))
	$(call banner, Releasing $(APP_NAME) v$(VERSION)...)
	@curl -fsSL https://raw.githubusercontent.com/sowwic/gh-workflows/$(GH_WORKFLOWS_REF)/scripts/release.py | \
		python3 - $(VERSION) --release-branch $(RELEASE_BRANCH) --develop-branch $(DEVELOP_BRANCH) $(if $(RELEASE_TITLE),--title "$(RELEASE_TITLE)")

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

.PHONY: dist
dist: ## Assemble dist/<package>_module (python + plug-ins)
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

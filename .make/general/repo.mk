# GitHub repository setup: `init-repo` for a new project, `sync-rulesets` for the rules of any repo,
# `setup-security` for the Advanced Security settings.
# Needs `git` and an authenticated `gh`. Include it after `general/python`, which sets the
# banner and the branch names.
#
# Set before including (all optional):
#   REPO_FLAGS         extra flags of `init-repo`, e.g. --private, --repo owner/name, --dry-run
#   RULESET_FLAGS      extra flags of `sync-rulesets`, e.g. --dry-run, --prune
#   RULESET_CHECKS     required checks of the develop branch, comma separated
#   SECURITY_FLAGS     flags of `setup-security`, e.g. --dependabot-alerts=off, --push-protection=on, --code-scanning=on, --dry-run
#   REPO_SETUP_URL     the script both targets run (default: repo_setup.py at GH_WORKFLOWS_REF)

REPO_FLAGS ?=
RULESET_FLAGS ?=
RULESET_CHECKS ?=
SECURITY_FLAGS ?=
REPO_SETUP_URL ?= https://raw.githubusercontent.com/sowwic/gh-workflows/$(GH_WORKFLOWS_REF)/scripts/repo_setup.py

.PHONY: init-repo
init-repo: ## New project only: create the GitHub repo with main + develop (default) and the standard rulesets
	$(call banner, Creating the GitHub repository of $(APP_NAME)...)
	@curl -fsSL $(REPO_SETUP_URL) | \
		python3 - init --release-branch $(RELEASE_BRANCH) --develop-branch $(DEVELOP_BRANCH) $(REPO_FLAGS)

.PHONY: sync-rulesets
sync-rulesets: ## Apply the standard rulesets to this repo (rulesets only, branches are never touched)
	$(call banner, Syncing the rulesets of $(APP_NAME)...)
	@curl -fsSL $(REPO_SETUP_URL) | \
		python3 - sync-rulesets --release-branch $(RELEASE_BRANCH) --develop-branch $(DEVELOP_BRANCH) $(if $(RULESET_CHECKS),--checks "$(RULESET_CHECKS)") $(RULESET_FLAGS)

.PHONY: setup-security
setup-security: ## Set the Advanced Security settings (SECURITY_FLAGS="--push-protection=on --code-scanning=on" to toggle)
	$(call banner, Setting up security of $(APP_NAME)...)
	@curl -fsSL $(REPO_SETUP_URL) | \
		python3 - setup-security $(SECURITY_FLAGS)

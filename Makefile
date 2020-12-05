# Do nothing by default.
.PHONY: default
default: ;


# Set some "configuration" variables.
SUBMODULE_DIRECTORY := homebrew-cask
CASK_PATH           := Casks/vscodium.rb

# Set a variable for the commit at the start of this invocation (which will be changed during the update).
PREVIOUS_COMMIT      = $(shell git -C "${SUBMODULE_DIRECTORY}" rev-parse HEAD)

# Update the submodule to the latest version, and cherry-pick any changes to the cask file.
# Note the use of spaces and tabs below for comments and commands, respectively.
# - `make` will not accept comments preceded by tabs (or, rather, will treat them as shell commands) but using spaces is fine, even if the formatting is a little weird.
.PHONY: update
update:
    # Print the submodule's current commit information for logging.
	git submodule status -- "${SUBMODULE_DIRECTORY}"
    # Update the cask submodule to the latest remote commit, which prints the new commit if it's different.
	git submodule update --remote -- "${SUBMODULE_DIRECTORY}"
    # Extract any submodule commits affecting the cask file into patches, then apply to the superproject.
	git -C "${SUBMODULE_DIRECTORY}" format-patch --stdout "${PREVIOUS_COMMIT}..HEAD" -- "${CASK_PATH}" | git am
    # Amend the submodule update onto the last cask-update patch, but only if an update was already applied in the previous step.
    # We neither want to amend an already-pushed commit nor have a bunch of useless commits that just bump the submodule version without also bumping the cask version.
	if [ "$$(git rev-parse --abbrev-ref HEAD)" = 'master' ] && [ "$$(git rev-parse HEAD)" != "$$(git rev-parse @{u})" ]; then \
		git commit --amend --no-edit -- "${SUBMODULE_DIRECTORY}"; \
	fi

# Do nothing by default.
.PHONY: default
default: ;


# Set some "configuration" variables.
SUBMODULE_DIRECTORY := homebrew-cask
CASK_PATH           := Casks/vscodium.rb

# Update the submodule to the latest version, and cherry-pick any changes to the cask file.
# Note the use of spaces and tabs below for comments and commands, respectively.
# - `make` will not accept comments preceded by tabs (or, rather, will treat them as shell commands) but using spaces is fine, even if the formatting is a little weird.
.PHONY: update
update:
    # Print the submodule's current commit information for logging.
	@git submodule status -- "${SUBMODULE_DIRECTORY}"

    # Update the cask submodule to the latest remote commit, which prints the new commit if it's different.
    # Also only fetch the very latest commit, since the submodule itself is used more for tracking what commit was last checked than actually needing history.
	@git submodule update --init --remote --depth=1 -- "${SUBMODULE_DIRECTORY}"

    # Add and fetch the submodule's origin as a remote for the superproject, since that seems to be the best way to get cherry-picking working.
	@git remote remove submodule
	@git remote add --fetch submodule "$$(git config --file=.gitmodules "submodule.${SUBMODULE_DIRECTORY}.url")"

    # Cherry-pick all the commits from the submodule that touch the cask file into the superproject.
    # Patching (the original method seen in the git history) only seems to work intermittently, especially when running this as a GitHub action.
	@git rev-list "@:./${SUBMODULE_DIRECTORY}..submodule/master" -- "${CASK_PATH}" | xargs -- git cherry-pick

    # Amend the submodule update onto the last cask-update patch, but only if an update was already applied in the previous step.
    # We neither want to amend an already-pushed commit nor have a bunch of useless commits that just bump the submodule version without also bumping the cask version.
	@if [ "$$(git rev-parse --abbrev-ref HEAD)" = 'master' ] && [ "$$(git rev-parse HEAD)" != "$$(git rev-parse @{u})" ]; then \
		git commit --amend --no-edit -- "${SUBMODULE_DIRECTORY}"; \
	fi

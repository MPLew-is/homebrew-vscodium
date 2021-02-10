# Do nothing by default.
.PHONY: default
default: ;

# Instead of silencing each command (which makes the code less readable and hinders debugging), make use of the special `.SILENT` target to prevent printing of commands unless the `VERBOSE` flag is set.
ifndef VERBOSE
.SILENT:
endif


# Set some "configuration" variables.
SUBMODULE_DIRECTORY := homebrew-cask
CASK_PATH           := Casks/vscodium.rb
PATCHED_CASK_PATH   := Casks/vscodium-with-vscode-extensions.rb
PATCH_PATH          := Casks/vscodium.rb.patch

# Update the submodule to the latest version, and cherry-pick any changes to the cask file.
# Note the use of spaces and tabs below for comments and commands, respectively.
# - `make` will not accept comments preceded by tabs (or, rather, will treat them as shell commands) but using spaces is fine, even if the formatting is a little weird.
.PHONY: update
update:
	git submodule status -- "${SUBMODULE_DIRECTORY}"
    # Only initialize and fetch the submodule, don't fully update it yet.
    # It will be walked through each applicable commit to allow the patch to be applied.
	git submodule update --init --depth=1 -- "${SUBMODULE_DIRECTORY}"
	git -C "${SUBMODULE_DIRECTORY}" fetch --shallow-since="$$(git -C "${SUBMODULE_DIRECTORY}" log -1 --pretty="format:%cI" HEAD)" origin

    # Walk through each commit that touches the Cask file and bring in those changes by applying a pre-defined patch.
	git -C "${SUBMODULE_DIRECTORY}" rev-list --reverse HEAD..origin/master -- "${CASK_PATH}" | xargs -L 1 -I{commit} -- "${MAKE}" patch-commit SUBMODULE_COMMIT={commit}


# If no specific commit provided via environment variable, just use the submodule's current `HEAD`.
SUBMODULE_COMMIT ?= $(shell git -C "${SUBMODULE_DIRECTORY}" rev-parse HEAD)

# Create a commit that is the patched contents of the cask formula at the provided `${SUBMODULE_COMMIT}` and that reuses that commit's author information.
# Essentially, we're trying to get as close to cherry-picking behavior as possible, but are forced to use a patch due to git not being smart enough to track the level of alteration being done to the formula file.
.PHONY: patch-commit
patch-commit: ${PATCHED_CASK_PATH}
    # Ensure that the version of the submodule that is committed is the one we want.
	git -C "${SUBMODULE_DIRECTORY}" reset --hard "${SUBMODULE_COMMIT}"

    # Re-build the patched formula from its sources (ignoring any timestamp comparisons, since this may be used to apply an older commit).
	"${MAKE}" --always-make "${PATCHED_CASK_PATH}"

    # Commit the new formula and the submodule using the submodule's commit (to emulate cherry-picking the submodule commit directly).
	git fetch --depth=1 "./${SUBMODULE_DIRECTORY}" HEAD
	git commit --reuse-message="${SUBMODULE_COMMIT}" --no-edit -- "${PATCHED_CASK_PATH}" "${SUBMODULE_DIRECTORY}"


# Build the patched cask formula from the cask file and the pre-defined patch.
${PATCHED_CASK_PATH}: ${SUBMODULE_DIRECTORY}/${CASK_PATH} ${PATCH_PATH}
	patch --strip=1 --output="${@}" "${SUBMODULE_DIRECTORY}/${CASK_PATH}" < "${PATCH_PATH}"

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
    # Only initialize and fetch the submodule, don't fully update it yet; it will be walked through each applicable commit to allow the patch to be applied.
    # We only need the commits between the current submodule commit and the current tip of its origin, but `git submodule update` doesn't support all of the various shallow options that fetch does so just start with a single commit and then unshallow the fetch separately.
    # The upstream has over 100,000 commits and likely has thousands of commits between `vscodium` updates, so we need to be extra judicious about what we fetch here.
	git submodule update --init --depth=1 -- "${SUBMODULE_DIRECTORY}"
	git -C "${SUBMODULE_DIRECTORY}" fetch --shallow-since="$$(git -C "${SUBMODULE_DIRECTORY}" log -1 --pretty="format:%cI" HEAD)" origin

    # Walk through each commit that touches the Cask file and bring in those changes by applying a pre-defined patch.
	git -C "${SUBMODULE_DIRECTORY}" rev-list --reverse HEAD..origin/master -- "${CASK_PATH}" | xargs -L 1 -I{commit} -- "${MAKE}" patch-commit SUBMODULE_COMMIT={commit}


# If no specific commit provided via environment variable, just use the submodule's current `HEAD`.
SUBMODULE_COMMIT ?= $(shell git -C "${SUBMODULE_DIRECTORY}" rev-parse HEAD)

# Create a commit that is the patched contents of the cask formula at the provided `${SUBMODULE_COMMIT}` and that reuses that commit's author information.
# Essentially, we're trying to get as close to cherry-picking behavior as possible, but are forced to use a patch due to git not being smart enough to track the level of alteration being done to the formula file.
.PHONY: patch-commit
patch-commit:
    # Ensure that the version of the submodule that is committed is the one we want.
	git -C "${SUBMODULE_DIRECTORY}" reset --hard "${SUBMODULE_COMMIT}"

    # Re-build the patched formula from its sources (ignoring any timestamp comparisons, since this may be used to apply an older commit).
	"${MAKE}" --always-make "${PATCHED_CASK_PATH}"

    # Fetch just the submodule's `HEAD` and ommit the new formula (and the submodule update) using the submodule's commit message/author information.
    # This emulates cherry-picking the submodule's commit directly (which was the original intent here) since we can't easily do that due to `patch`/`git apply` limitations with the scope of changes being made.
	git fetch --depth=1 "./${SUBMODULE_DIRECTORY}" HEAD
	git commit --reuse-message="${SUBMODULE_COMMIT}" -- "${PATCHED_CASK_PATH}" "${SUBMODULE_DIRECTORY}"
    # Rewrite the issue link generally present in either commit summary or body to point back to the upstream `homebrew-cask` repository.
    # We can't edit the message in the above command reusing all the other commit information, so rather than trying to extract all that information, edit the message, and then commit it all together, just edit the new commit afterwards with the summary we want.
    # The intent is to rewrite the below patterns while preserving all other parts of the commit (the body, author, timestamp, etc.):
    # - `... (#1234)` to `... (Homebrew/homebrew-cask#1234)` (as part of the subject)
    # - `Closes #1234.` to `Closes Homebrew/homebrew-cask#1234).` (as a complete line)
    # - `Fixes #1234.` to `Fixes Homebrew/homebrew-cask#1234).` (as a complete line)
	{ git log --format=%s --max-count=1 | sed -e 's:[(]\(#[0-9][0-9]*\)[)]$$:(Homebrew/homebrew-cask\1):'; git log --format=%b --max-count=1 | sed -e 's:^\([a-zA-Z][a-zA-Z]*\) \(#[0-9][0-9]*\)\.$$:\1 Homebrew/homebrew-cask\2.:'; } | git commit --amend --file=-


# Build the patched cask formula from the cask file and the pre-defined patch.
${PATCHED_CASK_PATH}: ${SUBMODULE_DIRECTORY}/${CASK_PATH} ${PATCH_PATH}
	patch --strip=1 --output="${@}" "${SUBMODULE_DIRECTORY}/${CASK_PATH}" < "${PATCH_PATH}"

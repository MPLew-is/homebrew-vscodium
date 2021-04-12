# VSCodium with original Visual Studio Code Extensions Gallery settings #

This repository is a [Homebrew Cask](https://github.com/Homebrew/homebrew-cask) tap containing a version of VSCodium with its Extensions Gallery configuration pointing at the original Visual Studio Code Extensions Marketplace by Microsoft, rather than the new [open-vsx one](https://open-vsx.org) which has far fewer extensions available. The provided [Cask formula](./Casks/vscodium.rb) uses the same binary as [the main VSCodium formula](https://github.com/Homebrew/homebrew-cask/tree/master/Casks/vscodium.rb), but with some overrides to the `product.json` settings file (as discussed in [the VSCodium documentation](https://github.com/VSCodium/vscodium/blob/c25fd7717b1033b2318772e8624e1b89ee562583/DOCS.md#extensions--marketplace)) being automatically applied during installation.

Note that [a recent VSCodium change](https://github.com/VSCodium/vscodium/pull/674) added support for an external `product.json` file, so it is this file that is created instead of patching the file internal to the app bundle itself, as in previous versions of this repository.

Inspired by the following issues, for context:

- [VSCodium/vscodium#418](https://github.com/VSCodium/vscodium/issues/418)
- [VSCodium/vscodium#430](https://github.com/VSCodium/vscodium/issues/430)

Auto-updates were previously disabled during installation, but with [the addition of the ability to use an external `product.json`](https://github.com/VSCodium/vscodium/pull/674), this is no longer a requirement and the default or existing settings are used. However, if you had this formula installed previously, auto-updates will not be automatically re-enabled for you and you must edit the `update.mode` key in your `settings.json` file accordingly.


## Usage ##

`brew install mplew-is/vscodium/vscodium-with-vscode-extensions`


## Updating and automation ##

[A `Makefile`](./Makefile) is provided with an `update` target to check the upstream Cask repository for updates and pull in the changes by applying [a pre-defined patch](./Casks/vscodium.rb.patch) to the upstream file. The `homebrew-cask` submodule is used and updated during this process to track which commit was last checked during the update as a reference for the next run.

This repository also has [a GitHub Actions workflow](./.github/workflows/update.yaml) to automatically run the `make` receipe periodically and automatically publish the changes to this repository.

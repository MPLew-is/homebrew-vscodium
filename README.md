# VSCodium with original Visual Studio Code Extensions Gallery settings #

This repository is a [Homebrew Cask](https://github.com/Homebrew/homebrew-cask) tap containing a version of VSCodium with its Extensions Gallery configuration pointing at the original Visual Studio Code Extensions Marketplace by Microsoft, rather than the new [open-vsx one](https://open-vsx.org) which has far fewer extensions available. The provided [Cask formula](./Casks/vscodium.rb) uses the same binary as [the main VSCodium formula](https://github.com/Homebrew/homebrew-cask/blob/77a17c3004a34fd7fe8468d261658bda82c0cf3c/Casks/vscodium.rb), but with a patch to the `product.json` settings file (as discussed in [the VSCodium documentation](https://github.com/VSCodium/vscodium/blob/c25fd7717b1033b2318772e8624e1b89ee562583/DOCS.md#extensions--marketplace)) being automatically applied during installation.

Inspired by the following issues, for context:

- [VSCodium/vscodium#418](https://github.com/VSCodium/vscodium/issues/418)
- [VSCodium/vscodium#430](https://github.com/VSCodium/vscodium/issues/430)

Additionally, auto-updates are disabled in your user `settings.json` as this patch would be overwritten when VSCodium updates itself; use `brew cask upgrade` instead of the built-in upgrade functionality.


## Usage ##

`brew cask install mplew-is/vscodium/vscodium`

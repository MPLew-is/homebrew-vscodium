cask "vscodium-with-vscode-extensions" do
  arch arm: "arm64", intel: "x64"

  version "1.85.1.23348"
  sha256 arm:   "f8faf508690aea341f820b32768ac365eb8a8ace6e47eedb7f62cb68e28bcac8",
         intel: "4cf1e86b22941db6c1f7d07ae0de31c1d1f627b68d0b45bc7d4942b8206a5970"

  url "https://github.com/VSCodium/vscodium/releases/download/#{version}/VSCodium.#{arch}.#{version}.dmg"
  name "VSCodium (with original Visual Studio Code Extensions Gallery configuration)"
  desc "Binary releases of VS Code without MS branding/telemetry/licensing"
  homepage "https://github.com/VSCodium/vscodium"

  auto_updates true
  depends_on macos: ">= :high_sierra"
  conflicts_with cask: [
    "visual-studio-code",
    "vscodium",
  ]

  app "VSCodium.app"
  binary "#{appdir}/VSCodium.app/Contents/Resources/app/bin/codium"

  zap trash: [
    "~/.vscode-oss",
    "~/Library/Application Support/VSCodium",
    "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.vscodium.sfl*",
    "~/Library/Caches/com.vscodium",
    "~/Library/Caches/com.vscodium.ShipIt",
    "~/Library/HTTPStorages/com.vscodium",
    "~/Library/Preferences/com.vscodium*.plist",
    "~/Library/Saved Application State/com.vscodium.savedState",
  ]

  postflight do
    require 'json'
    require 'fileutils'

    # Reset extensions gallery to mainline Visual Studio Code one by overriding some settings in an external `product.json`.
    # Support for this was added in [a recent VSCodium change](https://github.com/VSCodium/vscodium/pull/674).
    product_file_path = "#{Dir.home}/Library/Application Support/VSCodium/product.json"

    # Read exisitng product file if it exists, to not clobber any other settings the user might have.
    begin
      product = JSON.load(File.read(product_file_path))
    # Just use an empty hash otherwise.
    rescue
      product = {}
    end

    # Change needed settings and write back to external file.
    # Make sure we don't clobber more settings here than necessary, in case there is something else set in the `extensionsGallery` dictionary.
    extensionsGallerySettings = product['extensionsGallery'] || {}
    extensionsGallerySettings['serviceUrl'] = 'https://marketplace.visualstudio.com/_apis/public/gallery'
    extensionsGallerySettings['itemUrl']    = 'https://marketplace.visualstudio.com/items'
    product['extensionsGallery'] = extensionsGallerySettings

    # Make sure VSCodium's Application Support directory is actually created before we try to write a file into it.
    FileUtils.mkdir_p(File.dirname(product_file_path))
    File.write(product_file_path, JSON.pretty_generate(product))
  end

  # Since we previously forced auto-updating off, we need to alert users about the new functionality.
  # We don't want to blindly turn auto-updating back on in case the user doesn't want that for other reasons.
  caveats 'With the latest versions of VSCodium, extensions gallery override settings and auto-updating can now coexist; if you want to turn auto-updating back on, remove the `update.mode` setting from your `settings.json` file.'
end

cask "vscodium-with-vscode-extensions" do
  arch arm: "arm64", intel: "x64"

  version "1.79.0.23159"
  sha256 arm:   "24c78b06cd0a879205c8bba3bb283dd0a1722b51fe15ceff110bdc74eb1f595b",
         intel: "ec3746d1cc0f9f4bcc0426b0e1101d84feb8bb5a662db5eff5dbe0f668ee5ee7"

  url "https://github.com/VSCodium/vscodium/releases/download/#{version}/VSCodium.#{arch}.#{version}.dmg"
  name "VSCodium (with original Visual Studio Code Extensions Gallery configuration)"
  desc "Binary releases of VS Code without MS branding/telemetry/licensing"
  homepage "https://github.com/VSCodium/vscodium"

  auto_updates true
  conflicts_with cask: [
    "visual-studio-code",
    "vscodium",
  ]

  app "VSCodium.app"
  binary "#{appdir}/VSCodium.app/Contents/Resources/app/bin/codium"

  zap trash: [
    "~/.vscode-oss",
    "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.visualstudio.code.oss.sfl*",
    "~/Library/Application Support/VSCodium",
    "~/Library/Logs/VSCodium",
    "~/Library/Preferences/com.visualstudio.code.oss.helper.plist",
    "~/Library/Preferences/com.visualstudio.code.oss.plist",
    "~/Library/Saved Application State/com.visualstudio.code.oss.savedState",
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

cask "vscodium-with-vscode-extensions" do
  arch arm: "arm64", intel: "x64"

  version "1.93.1.24256"
  sha256 arm:   "83e2c4c9b45833c6b64235f42fa5ffa6560fd4c0c53bbdb21c4af18a7b1790b6",
         intel: "c79ca923cdba047d7f6ba806ca27ccf97bcf395269ab035210949ff7c6378ec0"

  url "https://github.com/VSCodium/vscodium/releases/download/#{version}/VSCodium.#{arch}.#{version}.dmg"
  name "VSCodium (with original Visual Studio Code Extensions Gallery configuration)"
  desc "Binary releases of VS Code without MS branding/telemetry/licensing"
  homepage "https://github.com/VSCodium/vscodium"

  # Not every GitHub release provides a file for macOS, so we check multiple
  # recent releases instead of only the "latest" release. NOTE: We should be
  # able to use `strategy :github_latest` when subsequent releases provide
  # files for macOS again.
  livecheck do
    url :url
    regex(/^VScodium[._-]#{arch}[._-]v?(\d+(?:\.\d+)+)\.(?:dmg|pkg)$/i)
    strategy :github_releases do |json, regex|
      json.map do |release|
        next if release["draft"] || release["prerelease"]

        release["assets"]&.map do |asset|
          match = asset["name"]&.match(regex)
          next if match.blank?

          match[1]
        end
      end.flatten
    end
  end

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
    "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.vscodium.sfl*",
    "~/Library/Application Support/VSCodium",
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

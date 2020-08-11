cask 'vscodium' do
  version '1.47.3'
  sha256 'd6576b9c3febdb72e74e038ed3cd69b3e4b30812ad109c984171461dec6708cb'

  url "https://github.com/VSCodium/vscodium/releases/download/#{version}/VSCodium.#{version}.dmg"
  appcast 'https://github.com/VSCodium/vscodium/releases.atom'
  name 'VSCodium (with original Visual Studio Code Extensions Gallery configuration)'
  homepage 'https://github.com/VSCodium/vscodium'

  auto_updates false
  conflicts_with cask: 'visual-studio-code'

  app 'VSCodium.app'
  binary "#{appdir}/VSCodium.app/Contents/Resources/app/bin/code"

  postflight do
    require 'json'

    # Reset extensions gallery to mainline Visual Studio Code one by overriding some settings in the app bundle.
    product_file_path = "#{appdir}/VSCodium.app/Contents/Resources/app/product.json"
    product = JSON.load(File.read(product_file_path))
    product['extensionsGallery']['serviceUrl'] = 'https://marketplace.visualstudio.com/_apis/public/gallery'
    product['extensionsGallery']['itemUrl'] = 'https://marketplace.visualstudio.com/items'
    File.write(product_file_path, JSON.pretty_generate(product))

    # Disable auto-updating in user-level VSCodium settings, or the above extensions patch would be overwritten.
    settings_file_path = "#{Dir.home}/Library/Application Support/VSCodium/User/settings.json"
    settings = JSON.load(File.read(settings_file_path))
    settings['update.mode'] = 'none'
    File.write(settings_file_path, JSON.pretty_generate(settings))

    # macOS quarantines apps when an internal file is modified; undo that to allow the app to open.
    system_command 'xattr',
                   args:  [ '-r',
                            '-d', 'com.apple.quarantine',
                            "#{appdir}/VSCodium.app"
                          ]
  end

  zap trash: [
               '~/Library/Application Support/VSCodium',
               '~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.visualstudio.code.oss.sfl*',
               '~/Library/Logs/VSCodium',
               '~/Library/Preferences/com.visualstudio.code.oss.helper.plist',
               '~/Library/Preferences/com.visualstudio.code.oss.plist',
               '~/Library/Saved Application State/com.visualstudio.code.oss.savedState',
               '~/.vscode-oss',
             ]

  caveats "Do not use the built-in update functionality with this version of VSCodium or the extensions marketplace settings will be overwritten; use `brew cask upgrade` instead."
end

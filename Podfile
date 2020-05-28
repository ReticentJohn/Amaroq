# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'DireFloof' do
  # Uncomment this line if you're using Swift or would like to use dynamic frameworks
  use_frameworks!

  # Pods for DireFloof
  pod 'AFNetworking', '~> 3.0'
  pod 'AFOAuth2Manager', '~> 3.0'
  pod 'DateTools', git: 'https://github.com/ReticentJohn/DateTools.git', branch: 'master'
  pod 'SDWebImage', '4.4.6'
  pod 'AnimatedGIFImageSerialization'
  pod 'TPKeyboardAvoiding'
  pod 'GMImagePicker', git: 'https://github.com/ReticentJohn/GMImagePicker.git', branch: 'master'
  pod 'YLProgressBar', '~> 3.10.1'
  pod 'CHTCollectionViewWaterfallLayout'
  pod 'PureLayout'
  pod 'MHVideoPhotoGallery', git: 'https://github.com/ReticentJohn/MHVideoPhotoGallery.git', branch: 'Audio-Dismiss-Fix'
  pod 'FCFileManager'
  pod 'GPUImage', git: 'https://github.com/ReticentJohn/GPUImage.git', branch: 'master'
  pod 'EmojiOne', podspec: 'DireFloof/Vendor/Emojione/emojione.podspec'
  pod 'RMPickerViewController', '~> 2.2.1'
  pod 'OAuth2', git: 'https://github.com/ReticentJohn/OAuth2-for-iOS.git', branch: 'master'
  pod 'ActiveLabel', git: 'https://github.com/ReticentJohn/ActiveLabel.swift.git', branch: 'master'
  pod 'UIImage-Resize'
  pod 'twitter-text', podspec: 'https://raw.githubusercontent.com/ReticentJohn/twitter-text/30-Char-Limit/objc/twitter-text.podspec'

post_install do | installer |
    
    installer.pods_project.targets.each do |target|
        if target.name == 'ActiveLabel'
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.0'
            end
        end
    end
    
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods-DireFloof/Pods-DireFloof-Acknowledgements.plist', 'DireFloof/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end

  target 'DireFloofTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'DireFloofUITests' do
    inherit! :search_paths
    # Pods for testing
  end
  
  target 'Amaroq Push' do
      inherit! :search_paths
  end

end

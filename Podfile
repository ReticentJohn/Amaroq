# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'DireFloof' do
  # Uncomment this line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for DireFloof
  pod 'AFNetworking', '~> 3.0'
  pod 'AFOAuth2Manager', '~> 3.0'
  pod 'DateTools'
  pod 'SDWebImage', '3.8.2'
  pod 'TTTAttributedLabel'
  pod 'AnimatedGIFImageSerialization'
  pod 'TPKeyboardAvoiding'
  pod 'GMImagePicker', git: 'https://github.com/ReticentJohn/GMImagePicker.git', branch: 'iOS10-Support'
  pod 'YLProgressBar', '~> 3.10.1'
  pod 'CHTCollectionViewWaterfallLayout'
  pod 'PureLayout'
  pod 'MHVideoPhotoGallery', git: 'https://github.com/ReticentJohn/MHVideoPhotoGallery.git', branch: 'Audio-Dismiss-Fix'
  pod 'twitter-text', podspec: 'https://raw.githubusercontent.com/ReticentJohn/twitter-text/30-Char-Limit/objc/twitter-text.podspec'
  pod 'FCFileManager'
  pod 'GPUImage', git: 'https://github.com/ReticentJohn/GPUImage.git', branch: 'master'
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'EmojiOne', podspec: 'DireFloof/Vendor/Emojione/emojione.podspec'
  pod 'RMPickerViewController', '~> 2.2.1'

post_install do | installer |
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

end

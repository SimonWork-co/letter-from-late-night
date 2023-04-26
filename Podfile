# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'Simonwork2' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Simonwork2
  pod 'FirebaseAuth'
  pod 'FirebaseFirestore'
  pod 'FirebaseAnalytics'
  pod 'FirebaseUI'
  pod 'FirebaseUI/Auth'
  pod 'Firebase/Core'
  pod 'FirebaseUI/Google'
  pod 'GoogleSignIn'
  pod 'Google-Mobile-Ads-SDK'
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
      end
    end
  end
  pod 'EmojiPicker', :git => 'https://github.com/htmlprogrammist/EmojiPicker'
  
  target 'LetterWidgetExtension' do
    pod 'FirebaseAuth'
    pod 'FirebaseFirestore'
    pod 'FirebaseUI'
    pod 'FirebaseUI/Auth'
    pod 'Firebase/Core'
    end
end

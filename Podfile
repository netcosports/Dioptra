platform :ios, '9.0'
source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/brightcove/BrightcoveSpecs.git'

use_frameworks!
inhibit_all_warnings!
#use_modular_headers!

install! 'cocoapods', :disable_input_output_paths => true

target 'Demo' do

  pod 'Astrolabe'

  pod 'Kingfisher'

  pod 'Dioptra/AV', :path => '.'
  pod 'Dioptra/DM', :path => '.'
  pod 'Dioptra/YT', :path => '.'

  pod 'Dioptra_Chromecast', :path => '.'

  pod 'Dioptra/Presentation', :path => '.'

  #pod 'Dioptra_BC', :path => './Dioptra_BC.podspec'

  pod 'SnapKit', '~> 4.0'
end

target 'iOSTests' do
  pod 'Dioptra/AV', :path => '.'
  pod 'Nimble', '~> 7.0'
  pod 'Quick'
  pod 'RxBlocking'
  pod 'RxTest'
end

pre_install do |installer|
    def installer.verify_no_static_framework_transitive_dependencies; end
end

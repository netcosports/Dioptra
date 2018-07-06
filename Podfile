platform :ios, '9.0'
source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/brightcove/BrightcoveSpecs.git'

use_frameworks!
inhibit_all_warnings!

target 'Demo' do
  pod 'Astrolabe/Loaders', :git => 'https://github.com/netcosports/Astrolabe'
  pod 'Dioptra/AV', :path => '.'
  pod 'Dioptra/DM', :path => '.'
  pod 'Dioptra/BC', :path => '.'
  #pod 'Dioptra/YT', :path => '.'
end

target 'iOSTests' do
  pod 'Dioptra/AV', :path => '.'
  pod 'Nimble', '~> 7.0'
  pod 'RxBlocking'
  pod 'RxTest'
end

pre_install do |installer|
  # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
  Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end

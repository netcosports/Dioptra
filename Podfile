platform :ios, '9.0'
source 'https://github.com/CocoaPods/Specs.git'

use_modular_headers!
inhibit_all_warnings!

target 'Demo' do
  pod 'Astrolabe/Loaders', :git => 'https://github.com/netcosports/Astrolabe', :branch => 'evolution'
  pod 'Dioptra/AV', :path => '.'
  pod 'Dioptra/DM', :path => '.'
end

target 'iOSTests' do
  pod 'Nimble', '~> 7.0'
  pod 'RxBlocking'
  pod 'RxTest'
end

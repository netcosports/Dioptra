Pod::Spec.new do |s|
  s.name = 'Dioptra'
  s.version = '5.1'
  s.summary = 'Video player RX based library'

  s.homepage = 'https://github.com/netcosports/Dioptra'
  s.author = {
    'Sergei Mikhan' => 'sergei@netcosports.com'
  }
  s.source = { :git => 'https://github.com/netcosports/Dioptra.git', :tag => s.version.to_s }
  s.license = { :type => "MIT" }

  s.ios.deployment_target = '9.0'
  s.default_subspec = 'Core'

  s.swift_versions = ['5.0', '5.1']

  s.subspec 'Core' do |sub|
    sub.source_files = 'Sources/Core/**/*.swift'
    sub.dependency 'RxSwift', '~> 4.5'
    sub.dependency 'RxCocoa', '~> 4.5'
    sub.dependency 'RxGesture', '~> 2.0'
  end

  s.subspec 'AV' do |sub|
    sub.source_files = 'Sources/AV/**/*.swift'
    sub.dependency 'Dioptra/Core'
  end

  s.subspec 'DM' do |sub|
    sub.source_files = 'Sources/DM/**/*.swift'
    sub.dependency 'DailymotionPlayerSDK'
    sub.dependency 'Dioptra/Core'
  end

  s.subspec 'YT' do |sub|
    sub.source_files = 'Sources/YT/**/*.swift'
    sub.dependency 'youtube-ios-player-helper'
    sub.dependency 'Dioptra/Core'
  end

  #FIXME: need to put this into separated pod
  s.subspec 'Presentation' do |sub|
    sub.source_files = 'Sources/Presentation/**/*.swift'
    sub.dependency 'RxSwift', '~> 4.5'
    sub.dependency 'RxCocoa', '~> 4.5'
    sub.dependency 'RxGesture', '~> 2.0'
  end

end

Pod::Spec.new do |s|
  s.name = 'Dioptra'
  s.version = '0.1'
  s.summary = 'Video player RX based library'

  s.homepage = 'https://github.com/netcosports/Dioptra'
  s.license = { :type => "MIT" }
  s.author = {
    'Sergei Mikhan' => 'sergei@netcosports.com'
  }
  s.source = { :git => 'https://github.com/netcosports/Dioptra.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.default_subspec = 'Core'

  s.subspec 'Core' do |sub|
    sub.source_files = 'Sources/Core/**/*.swift'
    sub.dependency 'RxSwift', '~> 4.0'
    sub.dependency 'RxCocoa', '~> 4.0'
    sub.dependency 'RxGesture', '~> 1.2'
    sub.dependency 'SnapKit'
  end

  s.subspec 'AV' do |sub|
    sub.source_files = 'Sources/AV/*.swift'
    sub.dependency 'Dioptra/Core'
  end

  s.subspec 'DM' do |sub|
    sub.source_files = 'Sources/DM/*.swift'
    sub.dependency 'DailymotionPlayerSDK'
    sub.dependency 'Dioptra/Core'
  end
end

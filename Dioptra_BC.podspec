Pod::Spec.new do |s|
  s.name = 'Dioptra_BC'
  s.version = '5.0'
  s.summary = 'Video player RX based library for BC'

  s.homepage = 'https://github.com/netcosports/Dioptra'
  s.author = {
    'Sergei Mikhan' => 'sergei@netcosports.com'
  }
  s.source = { :git => 'https://github.com/netcosports/Dioptra.git', :tag => s.version.to_s }
  s.license = { :type => "MIT" }

  s.ios.deployment_target = '9.0'
  s.swift_versions = ['5.0', '5.1']
  s.source_files = 'Sources/BC/**/*.swift'

  s.dependency 'Brightcove-Player-Core'
  s.dependency 'Dioptra/AV'

end

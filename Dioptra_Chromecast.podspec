Pod::Spec.new do |s|
  s.name = 'Dioptra_Chromecast'
  s.version = '5.0'
  s.summary = 'Video player RX based library for Chromecast'

  s.homepage = 'https://github.com/netcosports/Dioptra'
  s.author = {
    'Sergei Mikhan' => 'sergei@netcosports.com'
  }
  s.source = { :git => 'https://github.com/netcosports/Dioptra.git', :tag => s.version.to_s }
  s.license = { :type => "MIT" }

  s.static_framework = true
  s.ios.deployment_target = '9.0'
  s.swift_versions = ['5.0', '5.1', '5.2']
  s.source_files = 'Sources/Chromecast/*.swift'

  s.dependency 'google-cast-sdk'
  s.dependency 'Dioptra/Core'

end

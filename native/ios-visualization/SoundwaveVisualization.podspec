Pod::Spec.new do |s|
  s.name             = 'SoundwaveVisualization'
  s.version          = '0.0.2-native-SNAPSHOT'
  s.summary          = 'SoundWave native visualization core (iOS, no Flutter dependency).'
  s.homepage         = 'https://github.com/gengqifu/SoundWave'
  s.license          = { :file => '../../LICENSE' }
  s.author           = { 'SoundWave Team' => 'dev@soundwave.local' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '12.0'
  s.vendored_frameworks = 'SoundwaveVisualization.xcframework'
  s.swift_version    = '5.0'
end

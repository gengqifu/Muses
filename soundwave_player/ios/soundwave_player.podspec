#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint soundwave_player.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'soundwave_player'
  s.version          = '0.0.2'
  s.summary          = 'SoundWave audio visualization and export plugin.'
  s.description      = <<-DESC
SoundWave 提供音频可视化（波形/频谱）与数据导出能力的 Flutter 插件，内置 KissFFT/vDSP。
                       DESC
  s.homepage         = 'https://github.com/gengqifu/SoundWave'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'SoundWave Team' => 'dev@soundwave.local' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  # 调试：若指定本地原生 XCFramework 路径，则优先使用；否则依赖已发布的原生包。
  local_vis_path = ENV['SW_VIS_LOCAL_PATH'] || '../../native/ios-visualization'
  if File.exist?(local_vis_path)
    s.dependency 'SoundwaveVisualization', :path => local_vis_path
  else
    s.dependency 'SoundwaveVisualization', '0.0.2-native-SNAPSHOT'
  end

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'soundwave_player_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end

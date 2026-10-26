Pod::Spec.new do |s|
  s.name             = 'daylight_camera'
  s.version          = '0.1.0'
  s.summary          = 'Native-grade camera plugin for SocialScoreKeeper.'
  s.description      = <<-DESC
AVFoundation camera for SocialScoreKeeper, driven from Dart through one Pigeon contract.
                       DESC
  s.homepage         = 'https://github.com/DayLight-Creative-Technologies/daylight_camera'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'DayLight Creative Technologies' => 'steven@daylightcreative.tech' }
  s.source           = { :path => '.' }
  # The same sources the Swift package builds (ios/daylight_camera/Package.swift).
  s.source_files = 'daylight_camera/Sources/daylight_camera/**/*.swift'
  s.resource_bundles = {'daylight_camera_privacy' => ['daylight_camera/Sources/daylight_camera/PrivacyInfo.xcprivacy']}
  s.dependency 'Flutter'
  s.platform = :ios, '18.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '6.0'
end

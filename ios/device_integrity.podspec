#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint device_integrity.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'device_integrity'
  s.version          = '1.0.1'
  s.summary          = 'Flutter device integrity / attestation plugin (Play Integrity, SafetyDetect, DeviceCheck, App Attest).'
  s.description      = <<-DESC
A unified Flutter plugin for device attestation:
- Google Play Integrity API (classic + standard requests) on Android (GMS)
- Huawei SafetyDetect (SysIntegrity, URL check, User Detect, Wi-Fi Detect, AppsCheck) on Android (HMS)
- Apple DeviceCheck (DCDevice) and App Attest (DCAppAttestService) on iOS
DESC
  s.homepage         = 'https://github.com/leithalnajjar/device_integrity'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Laith Alnajjar' => 'info@ana-tech.net' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '14.0'
  s.frameworks       = 'DeviceCheck'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {'device_integrity_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end

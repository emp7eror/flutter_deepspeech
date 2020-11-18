#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_deepspeech.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_deepspeech'
  s.version          = '0.0.1'
  s.summary          = 'Deepspeech for flutter'
  s.description      = <<-DESC
Deepspeech for flutter
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  s.ios.vendored_libraries = 'lib/libdeepspeech.a'
  s.ios.frameworks = 'AudioToolbox', 'AVFoundation'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
      'DEFINES_MODULE' => 'YES',
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.user_target_xcconfig = { 'OTHER_LDFLAGS' => '-lc++' }
end

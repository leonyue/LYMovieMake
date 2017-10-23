#
#  Be sure to run `pod spec lint LYPopupMenu.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "LYMovieMake"
  s.version      = "0.0.1"
  s.summary      = "An iOS Video Editor Tool"
  s.description  = "An iOS Video Editor Tool Using native library"
  s.homepage     = "https://github.com/leonyue/LYMovieMake"
  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "leonyue" => "4940748@qq.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/leonyue/LYMovieMake.git", :tag => "#{s.version}" }
  s.source_files  = "LYMovieMake", "LYMovieMake/*"
  s.requires_arc = true

end

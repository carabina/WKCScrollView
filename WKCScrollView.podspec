Pod::Spec.new do |s|
s.name         = "WKCScrollView"
s.version      = "0.2.9"
s.summary      = "WKCScrollView is a view based on UIScrollView,and it has a viewsPool to store the visibleViews."
s.homepage     = "https://github.com/WeiKunChao/WKCScrollView.git"
s.license      = { :type => "MIT", :file => "LICENSE" }
s.author             = { "WeiKunChao" => "17736289336@163.com" }
s.platform     = :ios, "8.0"
s.source       = { :git => "https://github.com/WeiKunChao/WKCScrollView.git", :tag => "0.2.9" }
s.source_files  = "WKCScrollView/**/*.{h,m}"
s.public_header_files = "WKCScrollView/**/*.h"
s.frameworks = "Foundation", "UIKit"
s.requires_arc = true

end

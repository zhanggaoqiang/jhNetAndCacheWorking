Pod::Spec.new do |s|

  s.name         = "jhNetAndCacheWorking"
  s.version      = "0.0.1"
  s.summary      = "封装AF"
  s.description  = <<-DESC
                       封装AFNetworking,简单易用
                   DESC
  s.homepage     = "https://github.com/zhanggaoqiang/jhNetAndCacheWorking"
  s.license      = "MIT"
  s.authors            = { "张高强" => "835389423@qq.com" }
  s.platform     = :ios,"9.0"
  s.source       = { :git => "https://github.com/zhanggaoqiang/jhNetAndCacheWorking.git", :tag => s.version }
  s.source_files  = 'jhNetAndCacheWorking/**/*.{h,m}'
  s.requires_arc = true
end
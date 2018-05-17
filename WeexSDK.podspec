# coding: utf-8
Pod::Spec.new do |s|

  s.name         = "WeexSDK"

  s.version      = "0.18.0"

  s.summary      = "WeexSDK Source ."

  s.description  = <<-DESC
                   A framework for building Mobile cross-platform UI
                   DESC

  s.homepage     = "https://github.com/alibaba/weex"
  s.license = {
    :type => 'Copyright',
    :text => <<-LICENSE
           Alibaba-INC copyright
    LICENSE
  }
  s.authors      = { "cxfeng1"      => "cxfeng1@gmail.com",
                     "boboning"     => "ningli928@163.com",
                     "yangshengtao" => "yangshengtao1314@163.com",
                     "kfeagle"      => "sunjjbobo@163.com",
                     "acton393"     => "zhangxing610321@gmail.com"
                   }
  s.platform     = :ios
  s.ios.deployment_target = '8.0'
  s.source =  { :path => '.' }
  s.source_files = 'ios/sdk/WeexSDK/Sources/**/*.{h,m,mm,c,cpp}';
 
  s.resources = 'pre-build/*.js','ios/sdk/WeexSDK/Resources/wx_load_error@3x.png'

  s.user_target_xcconfig  = { 'FRAMEWORK_SEARCH_PATHS' => "'$(PODS_ROOT)/WeexSDK'" }
  s.requires_arc = true
  s.prefix_header_file = 'ios/sdk/WeexSDK/Sources/Supporting Files/WeexSDK-Prefix.pch'

#  s.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => '$(inherited) DEBUG=1' }

  s.private_header_files = 'ios/sdk/WeexSDK/Sources/Component/RecycleList/WXJSASTParser.h'
                            

  s.xcconfig = { "OTHER_LINK_FLAG" => '$(inherited) -ObjC'}

  s.frameworks = 'CoreMedia','MediaPlayer','AVFoundation','AVKit','JavaScriptCore', 'GLKit', 'OpenGLES', 'CoreText', 'QuartzCore', 'CoreGraphics'
  
  s.default_subspec='WeexCore'

  s.subspec 'WeexCore' do |w|
    w.source_files= 'weex_core/Source/base/**/*.{h,m,mm,c,cpp}',
                    'weex_core/Source/core/**/*.{h,m,mm,c,cpp}',
                    'weex_core/Source/include/**/*.{h,m,mm,c,cpp}',
                    'weex_core/Source/rapidjson/**/*.{h,m,mm,c,cpp}',
                    'weex_core/Source/iOS/**/*.{h,m,mm,c,cpp}'
    w.exclude_files = 'weex_core/Source/base/Compatible.cpp',
                    'weex_core/Source/core/api/WeexJSCoreApi.cpp',
                    'weex_core/Source/rapidjson/msinttypes'
    w.xcconfig = { 'USER_HEADER_SEARCH_PATHS' => '"weex_core/Source/base/.."/**' }
    w.xcconfig = { 'USER_HEADER_SEARCH_PATHS' => '"weex_core/Source/core/.."/**' }  
    w.xcconfig = { 'USER_HEADER_SEARCH_PATHS' => '"weex_core/Source/include/.."/**' }  
    w.xcconfig = { 'USER_HEADER_SEARCH_PATHS' => '"weex_core/Source/rapidjson/.."/**' }
    w.xcconfig = { 'USER_HEADER_SEARCH_PATHS' => '"weex_core/Source/iOS/.."/**' }
    w.header_mappings_dir = 'weex_core/Source'

    w.libraries = "stdc++"

  end

end

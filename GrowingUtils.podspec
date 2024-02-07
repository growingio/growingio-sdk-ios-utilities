Pod::Spec.new do |s|
  s.name             = 'GrowingUtils'
  s.version          = '1.2.2'
  s.summary          = 'iOS SDK of GrowingIO.'
  s.description      = <<-DESC
GrowingAnalytics具备自动采集基本的用户行为事件，比如访问和行为数据等。目前支持代码埋点、无埋点、可视化圈选、热图等功能。
                       DESC
  s.homepage         = 'https://www.growingio.com/'
  s.license          = { :type => 'Apache2.0', :file => 'LICENSE' }
  s.author           = { 'GrowingIO' => 'support@growingio.com' }
  s.source           = { :git => 'https://github.com/growingio/growingio-sdk-ios-utilities.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.tvos.deployment_target = '12.0'
  s.watchos.deployment_target = '7.0'
  # s.visionos.deployment_target = '1.0'
  s.requires_arc = true
  s.default_subspec = "TrackerCore"

  s.subspec 'TrackerCore' do |tracker|
    tracker.source_files = 'Sources/TrackerCore/**/*{.h,.m,.c,.cpp,.mm}'
    tracker.resource_bundles = {'GrowingUtils' => ['Sources/TrackerCore/Resources/**/*']}
  end

  s.subspec 'AutotrackerCore' do |autotracker|
    autotracker.ios.deployment_target = '10.0'
    autotracker.tvos.deployment_target = '12.0'
    autotracker.dependency 'GrowingUtils/TrackerCore'
    autotracker.source_files = 'Sources/AutotrackerCore/**/*{.h,.m,.c,.cpp,.mm}'
  end
end

#!/usr/bin/env ruby
# 修复项目Info.plist自动生成设置

require 'xcodeproj'

# 打开项目
project_path = 'lvji.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 获取主target
target = project.targets.first

# 设置Info.plist自动生成
target.build_configurations.each do |config|
  # 启用Info.plist自动生成
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  
  # 确保不使用现有的Info.plist文件
  if config.build_settings['INFOPLIST_FILE']
    config.build_settings.delete('INFOPLIST_FILE')
  end

  # 其他可能需要的设置
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.example.lvji'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  
  # Info.plist相关键值设置
  config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = '旅迹'
  config.build_settings['INFOPLIST_KEY_UIApplicationSceneManifest_Generation'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
end

# 保存项目
project.save

puts "已更新项目配置，启用Info.plist自动生成" 
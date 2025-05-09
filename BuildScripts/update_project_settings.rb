#!/usr/bin/env ruby
# 更新项目设置以确保Info.plist正确生成

require 'xcodeproj'

# 打开项目
project_path = 'lvji.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 获取主target
target = project.targets.first
puts "正在处理Target: #{target.name}"

# 更新所有构建配置
target.build_configurations.each do |config|
  puts "更新构建配置: #{config.name}"
  
  # 设置Info.plist自动生成
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  puts "设置 GENERATE_INFOPLIST_FILE = YES"
  
  # 确保INFOPLIST_FILE为空
  if config.build_settings['INFOPLIST_FILE'] && !config.build_settings['INFOPLIST_FILE'].empty?
    puts "删除 INFOPLIST_FILE (当前值: #{config.build_settings['INFOPLIST_FILE']})"
    config.build_settings.delete('INFOPLIST_FILE')
  else
    puts "INFOPLIST_FILE 未设置或已为空"
  end
  
  # 添加所需的Info.plist键值
  info_keys = {
    'INFOPLIST_KEY_CFBundleDisplayName' => '旅迹',
    'INFOPLIST_KEY_UIApplicationSceneManifest_Generation' => 'YES',
    'INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents' => 'YES',
    'INFOPLIST_KEY_UILaunchScreen_Generation' => 'YES',
    'INFOPLIST_KEY_UISupportedInterfaceOrientations' => 'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight',
    'INFOPLIST_KEY_NSCameraUsageDescription' => '用于拍照标记位置',
    'INFOPLIST_KEY_NSLocationWhenInUseUsageDescription' => '用于标记照片位置和朋友位置共享',
    'INFOPLIST_KEY_NSPhotoLibraryUsageDescription' => '用于保存位置标记的照片'
  }
  
  info_keys.each do |key, value|
    config.build_settings[key] = value
    puts "设置 #{key} = #{value}"
  end
end

# 保存项目
project.save
puts "项目设置已更新，Info.plist将自动生成" 
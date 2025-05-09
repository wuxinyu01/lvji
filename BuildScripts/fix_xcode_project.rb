#!/usr/bin/env ruby
# 修复Xcode项目配置，解决Info.plist生成问题

require 'xcodeproj'

puts "开始修复Xcode项目配置..."

# 打开项目
project_path = 'lvji.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 获取主target
target = project.targets.first
puts "正在处理Target: #{target.name}"

# 1. 检查并移除资源构建阶段中的Info.plist文件
puts "\n第1步: 检查资源构建阶段..."
resources_phase = target.build_phases.find { |phase| phase.isa == 'PBXResourcesBuildPhase' }

if resources_phase
  # 检查是否存在Info.plist相关文件
  info_plist_files = []
  
  resources_phase.files.each do |build_file|
    file_ref = build_file.file_ref
    if file_ref && file_ref.path && file_ref.path.include?('Info.plist')
      info_plist_files << build_file
      puts "发现资源中的Info.plist文件: #{file_ref.path}"
    end
  end
  
  # 移除找到的Info.plist文件
  if info_plist_files.any?
    info_plist_files.each do |file|
      resources_phase.files.delete(file)
      puts "已从资源构建阶段移除: #{file.file_ref.path}"
    end
  else
    puts "资源构建阶段中未发现Info.plist文件"
  end
else
  puts "未找到资源构建阶段"
end

# 2. 更新构建配置
puts "\n第2步: 更新构建配置..."
target.build_configurations.each do |config|
  puts "更新构建配置: #{config.name}"
  
  # 设置Info.plist自动生成
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  puts "- 设置 GENERATE_INFOPLIST_FILE = YES"
  
  # 确保INFOPLIST_FILE为空
  if config.build_settings['INFOPLIST_FILE'] && !config.build_settings['INFOPLIST_FILE'].empty?
    puts "- 删除 INFOPLIST_FILE (当前值: #{config.build_settings['INFOPLIST_FILE']})"
    config.build_settings.delete('INFOPLIST_FILE')
  else
    puts "- INFOPLIST_FILE 未设置或已为空"
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
    'INFOPLIST_KEY_NSPhotoLibraryUsageDescription' => '用于保存位置标记的照片',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.example.lvji'
  }
  
  info_keys.each do |key, value|
    config.build_settings[key] = value
    puts "- 设置 #{key} = #{value}"
  end
end

# 3. 确保代码签名设置正确
puts "\n第3步: 检查代码签名设置..."
target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
  config.build_settings['CODE_SIGNING_ALLOWED'] = 'YES'
  config.build_settings['CODE_SIGN_IDENTITY'] = '-'
  puts "已为 #{config.name} 配置设置代码签名选项"
end

# 保存项目
project.save
puts "\n✅ 项目配置已更新，Info.plist将会自动生成"
puts "请重新构建项目" 
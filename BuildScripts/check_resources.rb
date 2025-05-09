#!/usr/bin/env ruby
# 检查并修复资源构建阶段中可能存在的Info.plist文件

require 'xcodeproj'

# 打开项目
project_path = 'lvji.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 获取主target
target = project.targets.first

# 检查资源构建阶段
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
    
    # 保存项目
    project.save
    puts "项目文件已更新"
  else
    puts "资源构建阶段中未发现Info.plist文件"
  end
else
  puts "未找到资源构建阶段"
end 
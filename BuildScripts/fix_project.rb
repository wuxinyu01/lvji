#!/usr/bin/env ruby
# 修复项目文件中的Info.plist引用问题

require 'xcodeproj'

# 打开项目
project_path = 'lvji.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 获取主target
target = project.targets.first

# 查找Copy Bundle Resources阶段
copy_phase = target.build_phases.find { |phase| phase.isa == 'PBXResourcesBuildPhase' }

# 查找Info.plist文件引用
info_plist_ref = nil
copy_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  if file_ref && file_ref.path && file_ref.path.end_with?('Info.plist')
    info_plist_ref = build_file
    break
  end
end

# 如果找到了Info.plist引用，将其从Copy Bundle Resources中移除
if info_plist_ref
  copy_phase.files.delete(info_plist_ref)
  puts "已从Copy Bundle Resources中移除Info.plist文件"
else
  puts "在Copy Bundle Resources中未找到Info.plist文件"
end

# 保存项目
project.save

puts "项目文件已更新" 
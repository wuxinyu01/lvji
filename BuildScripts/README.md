# Xcode项目修复脚本

这个目录包含了解决Xcode项目构建问题的脚本。

## 解决Info.plist生成问题

如果你遇到以下错误：

```
Cannot code sign because the target does not have an Info.plist file and one is not being generated automatically. Apply an Info.plist file to the target using the INFOPLIST_FILE build setting or generate one automatically by setting the GENERATE_INFOPLIST_FILE build setting to YES (recommended).
```

请运行以下脚本来修复此问题：

```bash
ruby BuildScripts/fix_xcode_project.rb
```

该脚本会执行以下操作：

1. 检查并移除资源构建阶段中可能存在的Info.plist文件
2. 更新项目构建配置，启用Info.plist自动生成
3. 设置正确的代码签名选项

运行脚本后，重新构建项目即可解决问题。

## 其他脚本说明

- `fix_infoplist_settings.rb`: 只修复Info.plist自动生成设置
- `check_resources.rb`: 检查并修复资源构建阶段中的Info.plist文件
- `update_project_settings.rb`: 更新项目构建设置

## 常见问题解决

如果运行脚本后仍然存在问题，可以尝试以下方法：

1. 确保BuildSettings.xcconfig中包含正确的设置：
   ```
   GENERATE_INFOPLIST_FILE = YES
   USE_GENERATED_INFOPLIST_FILE = YES
   ```

2. 在Xcode中，选择项目 > target > Build Settings，确认"Generate Info.plist File"设置为YES

3. 如果项目中存在手动创建的Info.plist文件，确保它不会与自动生成的文件冲突 
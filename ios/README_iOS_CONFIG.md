# iOS特定配置指南

## 1. 应用图标配置

### 自动生成图标（推荐）
使用提供的Python脚本自动从Logo文件夹生成所有所需尺寸的iOS图标：

```bash
# 在项目根目录运行
python ios/scripts/generate_ios_icons.py
```

该脚本会自动：
- 从 `../Logo/logo/` 目录读取源图标
- 生成所有iOS所需尺寸的PNG图标
- 使用高质量的LANCZOS重采样算法
- 自动优化输出的PNG文件

### 手动替换图标
如需手动替换，在 `ios/Runner/Assets.xcassets/AppIcon.appiconset/` 目录中替换以下图标文件：

### iPhone图标尺寸：
- Icon-App-20x20@2x.png (40x40)
- Icon-App-20x20@3x.png (60x60)
- Icon-App-29x29@1x.png (29x29)
- Icon-App-29x29@2x.png (58x58)
- Icon-App-29x29@3x.png (87x87)
- Icon-App-40x40@2x.png (80x80)
- Icon-App-40x40@3x.png (120x120)
- Icon-App-60x60@2x.png (120x120)
- Icon-App-60x60@3x.png (180x180)

### iPad图标尺寸：
- Icon-App-20x20@1x.png (20x20)
- Icon-App-40x40@1x.png (40x40)
- Icon-App-76x76@1x.png (76x76)
- Icon-App-76x76@2x.png (152x152)
- Icon-App-83.5x83.5@2x.png (167x167)

### App Store图标：
- Icon-App-1024x1024@1x.png (1024x1024)

## 2. 启动画面配置
在 `ios/Runner/Base.lproj/LaunchScreen.storyboard` 中自定义启动画面

## 3. 代码签名配置（发布时需要）
在Xcode中配置：
1. 打开 `ios/Runner.xcworkspace`
2. 选择Runner项目 → Signing & Capabilities
3. 配置Team和Bundle Identifier
4. 选择适当的Provisioning Profile

## 4. App Store Connect配置
1. 创建App Store Connect记录
2. 配置应用元数据
3. 上传应用截图
4. 设置应用描述和关键词

## 5. 推送通知配置（如需要）
1. 在Apple Developer Portal启用Push Notifications
2. 在Info.plist中添加推送权限
3. 在AppDelegate.swift中配置推送处理

## 6. 深度链接配置（如需要）
在Info.plist中添加URL Schemes：
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.openlist.mobile</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>openlist</string>
        </array>
    </dict>
</array>
```

## 7. 网络安全配置
### ⚠️ 重要：本地HTTP访问配置
OpenList需要访问本地HTTP服务（如 `http://127.0.0.1`），这在iOS中需要特殊配置。

已配置的网络安全设置：
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.0</string>
        </dict>
        <key>127.0.0.1</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.0</string>
        </dict>
    </dict>
</dict>
```

### 为什么需要这个配置？
1. **iOS App Transport Security (ATS)** 默认阻止所有HTTP连接
2. **本地服务访问** - OpenList需要连接到 `http://127.0.0.1` 的本地服务
3. **开发和调试** - 允许连接到本地开发服务器
4. **安全性平衡** - 仅为本地环回地址提供例外，保持 ATS 默认保护

### 支持的本地地址：
- `localhost` - 标准本地主机名
- `127.0.0.1` - IPv4回环地址

### 生产环境建议：
如果生产版本不需要访问本地HTTP服务，可以进一步移除 `NSExceptionDomains` 的本地例外配置。

## 8. 后台运行限制
iOS 不支持应用开机自动启动，也不保证服务器在应用进入后台后持续运行。应用进入后台时会申请一段有限的后台执行时间，用于完成正在进行的工作；系统可随时结束这段时间。后台上传使用系统后台 URL session，不代表 Core 服务器可持续运行。

当前没有配置 `UIBackgroundModes` 的 fetch 或 processing 模式；只有在实现并验证对应的系统任务处理逻辑后，才应声明这些后台模式。

## 9. 网络与文件访问说明
`NSLocalNetworkUsageDescription` 用于说明应用访问局域网的用途：连接局域网服务器，以及用户显式启用 LAN 模式时向同一网络提供服务。

文件选择与下载目录选择由系统文件选择器处理。选择图片或视频上传时，系统文件/媒体选择器可能需要照片图库访问；应用不直接使用相机或麦克风。文件访问权限由用户在系统文件选择器中选择位置时授予。

## 10. 构建配置
- 最低iOS版本：12.0
- 支持设备：arm64架构
- 状态栏样式：默认样式

## 构建命令
```bash
# 调试构建
flutter build ios --debug

# 发布构建（无代码签名）
flutter build ios --release --no-codesign

# 发布构建（带代码签名）
flutter build ios --release
```

## 发布到App Store
1. 在Xcode中Archive项目
2. 通过Xcode Organizer上传到App Store Connect
3. 在App Store Connect中提交审核
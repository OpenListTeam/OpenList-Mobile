# OpenList-Mobile 项目架构文档

## 项目概述

**OpenList-Mobile** 是一个基于 [OpenList](https://github.com/OpenListTeam/OpenList) 的移动端文件服务器应用，使用 Flutter 框架开发。支持局域网文件共享、远程访问和在线管理。

- **技术栈**: Flutter + Dart + Go (Gomobile) + Kotlin (Android) + Swift (iOS)
- **支持平台**: Android (主要), iOS (实验性)
- **版本**: 4.2.2+1
- **Flutter版本**: 3.32.7
- **许可证**: AGPL v3

---

## 整体架构

项目采用**三层架构**设计：

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter UI 层                          │
│  (lib/pages, lib/widgets, lib/utils)                    │
│  - 用户界面展示                                           │
│  - 业务逻辑处理                                           │
│  - 状态管理 (GetX)                                       │
└─────────────────────────────────────────────────────────┘
                          ↓ Pigeon (跨平台通信)
┌─────────────────────────────────────────────────────────┐
│                   原生平台层                              │
│  Android (Kotlin)          iOS (Swift)                  │
│  - 服务管理                                               │
│  - 配置存储                                               │
│  - 平台特性                                               │
└─────────────────────────────────────────────────────────┘
                          ↓ JNI / Go Mobile
┌─────────────────────────────────────────────────────────┐
│                   Go 核心层                               │
│  (openlist-lib/openlistlib)                             │
│  - OpenList服务器核心                                    │
│  - 文件服务逻辑                                          │
│  - 数据库管理                                            │
└─────────────────────────────────────────────────────────┘
```

---

## 目录结构

```
/workspace/
├── lib/                    # Flutter Dart代码
│   ├── main.dart           # 应用入口
│   ├── contant/            # 常量定义
│   ├── generated/          # 自动生成的国际化代码
│   ├── l10n/               # 国际化资源文件
│   ├── pages/              # UI页面
│   │   ├── openlist/       # OpenList控制页面
│   │   ├── settings/       # 设置页面
│   │   ├── web/            # WebView页面
│   │   └── download_manager_page.dart  # 下载管理
│   ├── utils/              # 工具类
│   └── widgets/            # UI组件
│
├── android/                # Android原生代码
│   └── app/src/main/
│       ├── kotlin/com/openlist/mobile/
│       │   ├── App.kt              # Application类
│       │   ├── MainActivity.kt     # 主Activity
│       │   ├── OpenListService.kt  # 后台服务
│       │   ├── bridge/             # Flutter桥接类
│       │   ├── config/             # 配置管理
│       │   ├── model/              # 数据模型
│       │   └── utils/              # 工具类
│       └── res/            # Android资源
│
├── ios/                    # iOS原生代码
│   └── Runner/
│       ├── AppDelegate.swift       # 应用入口
│       ├── OpenListManager.swift   # OpenList管理
│       ├── Bridges/                # Flutter桥接类
│       └── PigeonApi.swift         # Pigeon API
│
├── openlist-lib/           # Go核心库
│   └── openlistlib/
│       ├── server.go      # 服务器控制
│       ├── common.go      # 公共函数
│       ├── settings.go    # 配置设置
│       └── internal/      # 内部模块
│
├── pigeons/                # Pigeon定义文件
│   └── pigeon.dart        # 跨平台API定义
│
├── assets/                 # Flutter资源
├── test/                   # 测试代码
└── pubspec.yaml           # Flutter依赖配置
```

---

## 核心模块详解

### 1. Flutter UI层

#### 1.1 应用入口 ([lib/main.dart](file:///workspace/lib/main.dart))

**关键类**:
- `MyApp`: 应用根Widget，配置主题、国际化、路由
- `MyHomePage`: 主页面，包含底部导航栏和页面切换逻辑
- `_MainController`: 主页面控制器，管理页面索引

**初始化流程**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. 初始化语言控制器
  Get.put(LanguageController());
  
  // 2. 初始化通知管理器
  await NotificationManager.initialize();
  
  // 3. 初始化服务管理器
  await ServiceManager.instance.initialize();
  
  // 4. iOS首次启动自动启动服务
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final isRunning = await ServiceManager.instance.checkServiceStatus();
    if (!isRunning) {
      await ServiceManager.instance.startService();
    }
  }
  
  runApp(const MyApp());
}
```

#### 1.2 OpenList控制页面 ([lib/pages/openlist/openlist.dart](file:///workspace/lib/pages/openlist/openlist.dart))

**关键类**:
- `OpenListScreen`: OpenList服务控制界面
- `OpenListController`: 服务状态和日志管理控制器
- `MyEventReceiver`: Pigeon事件接收器

**主要功能**:
- 服务启动/停止控制
- 实时日志显示
- 管理员密码设置
- 配置编辑入口
- 桌面快捷方式添加
- 版本检查和更新

#### 1.3 设置页面 ([lib/pages/settings/settings.dart](file:///workspace/lib/pages/settings/settings.dart))

**功能模块**:
- 权限管理（存储、通知）
- 语言设置（中文/英文/跟随系统）
- 自动更新检查
- WakeLock（保持唤醒）
- 开机自启动
- 自动打开Web页面
- 数据目录设置
- 静默跳转应用
- 故障排查入口

#### 1.4 服务管理器 ([lib/utils/service_manager.dart](file:///workspace/lib/utils/service_manager.dart))

**核心职责**:
- 统一管理Android和iOS的服务生命周期
- 提供服务状态流（Stream）供UI监听
- 定期检查服务状态（30秒间隔）
- 处理原生端的状态变化通知

**关键方法**:
```dart
class ServiceManager {
  // 启动服务
  Future<bool> startService()
  
  // 停止服务
  Future<bool> stopService()
  
  // 检查服务状态
  Future<bool> checkServiceStatus()
  
  // 重启服务
  Future<bool> restartService()
  
  // 电池优化相关
  Future<bool> isBatteryOptimizationIgnored()
  Future<bool> requestIgnoreBatteryOptimization()
}
```

#### 1.5 下载管理器 ([lib/utils/download_manager.dart](file:///workspace/lib/utils/download_manager.dart))

**核心功能**:
- 后台文件下载（使用Dio）
- 下载进度跟踪和通知
- 任务状态管理（pending/downloading/completed/failed/cancelled）
- 下载目录管理（OpenList专用目录）
- 文件打开和APK安装处理

**关键类**:
- `DownloadTask`: 下载任务数据模型
- `DownloadManager`: 下载管理核心类
- `DownloadController`: 下载控制器（兼容旧版）

---

### 2. 原生平台层 - Android

#### 2.1 Application类 ([android/app/src/main/kotlin/com/openlist/mobile/App.kt](file:///workspace/android/app/src/main/kotlin/com/openlist/mobile/App.kt))

**职责**:
- 应用全局初始化
- OpenList早期初始化（为开机启动做准备）
- 全局异常处理器设置

#### 2.2 OpenListService ([android/app/src/main/kotlin/com/openlist/mobile/OpenListService.kt](file:///workspace/android/app/src/main/kotlin/com/openlist/mobile/OpenListService.kt))

**核心后台服务**，实现保活机制：

**关键特性**:
- 前台服务（Foreground Service）保活
- WakeLock保持唤醒
- 定期数据库同步（5分钟间隔）
- 通知栏控制（启动/停止/复制地址）
- 开机自启动支持

**生命周期管理**:
```kotlin
override fun onCreate() {
    // 1. 创建前台通知
    // 2. 注册广播接收器
    // 3. 添加OpenList监听器
    // 4. 获取WakeLock
}

override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    // 检查手动停止标志
    // 启动OpenList后端
    return START_STICKY // 保活
}
```

#### 2.3 Bridge桥接类

**ServiceBridge** ([android/app/src/main/kotlin/com/openlist/mobile/bridge/ServiceBridge.kt](file:///workspace/android/app/src/main/kotlin/com/openlist/mobile/bridge/ServiceBridge.kt)):
- Flutter与Android服务通信桥梁
- MethodChannel处理服务控制请求
- 电池优化相关操作

**AppConfigBridge**:
- 应用配置管理（SharedPreferences）
- WakeLock、开机启动、自动更新等设置

**CommonBridge**:
- Toast显示
- Intent启动
- 设备信息获取

#### 2.4 OpenList模型 ([android/app/src/main/kotlin/com/openlist/mobile/model/openlist/OpenList.kt](file:///workspace/android/app/src/main/kotlin/com/openlist/mobile/model/openlist/OpenList.kt))

**核心职责**:
- 调用Go库（Openlistlib）接口
- 实现Event和LogCallback接口
- 管理监听器列表
- 数据库强制同步

**关键方法**:
```kotlin
object OpenList : Event, LogCallback {
    fun init()          // 初始化OpenList
    fun startup()       // 启动服务器
    fun shutdown()      // 关闭服务器
    fun isRunning()     // 检查运行状态
    fun setAdminPassword(pwd: String)  // 设置管理员密码
    fun forceDatabaseSync()  // 强制数据库同步
}
```

---

### 3. 原生平台层 - iOS

#### 3.1 OpenListManager ([ios/Runner/OpenListManager.swift](file:///workspace/ios/Runner/OpenListManager.swift))

**iOS核心管理类**:

**职责**:
- OpenList服务器生命周期管理
- 初始化和配置设置
- 事件和日志回调处理
- Flutter状态通知

**关键方法**:
```swift
class OpenListManager {
    func initialize(event: OpenListEventHandler, logger: OpenListLogCallback)
    func startServer()
    func stopServer(timeout: Int64 = 5000)
    func isRunning() -> Bool
    func setAdminPassword(_ pwd: String)
    func forceDBSync()
}
```

#### 3.2 事件处理类

**OpenListEventHandler**:
- 处理启动错误、关闭、进程退出事件
- 转发事件到Flutter端

**OpenListLogCallback**:
- 接收Go库日志
- 转发日志到Flutter端显示

---

### 4. Go核心层

#### 4.1 服务器控制 ([openlist-lib/openlistlib/server.go](file:///workspace/openlist-lib/openlistlib/server.go))

**核心API**:

```go
// 初始化OpenList
func Init(event Event, cb LogCallback) error

// 启动服务器
func Start()

// 关闭服务器（timeout毫秒）
func Shutdown(timeout int64) error

// 检查是否运行
func IsRunning(t string) bool

// 强制数据库同步（WAL checkpoint）
func ForceDBSync() error
```

**关键实现**:
- 注册启动失败和关闭钩子
- 设置日志格式化器
- SQLite WAL checkpoint强制同步

#### 4.2 配置设置 ([openlist-lib/openlistlib/settings.go](file:///workspace/openlist-lib/openlistlib/settings.go))

**配置API**:
```go
func SetConfigData(path string)    // 设置数据目录
func SetConfigLogStd(b bool)       // 启用标准输出日志
func SetConfigDebug(b bool)        // 启用调试模式
func SetConfigNoPrefix(b bool)     // 无前缀模式
func SetAdminPassword(pwd string)  // 设置管理员密码
```

#### 4.3 公共函数 ([openlist-lib/openlistlib/common.go](file:///workspace/openlist-lib/openlistlib/common.go))

**网络工具**:
```go
func GetOutboundIP() (net.IP, error)      // 获取出口IP
func GetOutboundIPString() string         // 获取出口IP字符串
```

---

## 跨平台通信机制

### Pigeon通信框架

项目使用 **Pigeon** 实现Flutter与原生平台的双向通信。

#### API定义 ([pigeons/pigeon.dart](file:///workspace/pigeons/pigeon.dart))

**HostApi（Flutter调用原生）**:

```dart
@HostApi()
abstract class AppConfig {
  bool isWakeLockEnabled();
  void setWakeLockEnabled(bool enabled);
  bool isStartAtBootEnabled();
  void setStartAtBootEnabled(bool enabled);
  bool isAutoCheckUpdateEnabled();
  void setAutoCheckUpdateEnabled(bool enabled);
  bool isAutoOpenWebPageEnabled();
  void setAutoOpenWebPageEnabled(bool enabled);
  String getDataDir();
  void setDataDir(String dir);
  bool isSilentJumpAppEnabled();
  void setSilentJumpAppEnabled(bool enabled);
}

@HostApi()
abstract class NativeCommon {
  bool startActivityFromUri(String intentUri);
  int getDeviceSdkInt();
  String getDeviceCPUABI();
  String getVersionName();
  int getVersionCode();
  void toast(String msg);
  void longToast(String msg);
}

@HostApi()
abstract class Android {
  void addShortcut();
  void startService();
  void setAdminPwd(String pwd);
  int getOpenListHttpPort();
  bool isRunning();
  String getOpenListVersion();
}
```

**FlutterApi（原生调用Flutter）**:

```dart
@FlutterApi()
abstract class Event {
  void onServiceStatusChanged(bool isRunning);
  void onServerLog(int level, String time, String log);
}
```

#### 生成代码位置

- Flutter端: [lib/generated_api.dart](file:///workspace/lib/generated_api.dart)
- Android端: [android/app/src/main/java/com/openlist/pigeon/GeneratedApi.java](file:///workspace/android/app/src/main/java/com/openlist/pigeon/GeneratedApi.java)
- iOS端: [ios/Runner/PigeonApi.swift](file:///workspace/ios/Runner/PigeonApi.swift)

---

## 依赖关系图

### Flutter依赖 (pubspec.yaml)

**核心依赖**:
| 包名 | 版本 | 用途 |
|------|------|------|
| flutter | SDK | UI框架 |
| get | ^4.6.6 | 状态管理 |
| pigeon | ^26.0.0 | 跨平台通信 |
| flutter_inappwebview | ^6.0.0 | WebView |
| dio | ^5.4.0 | HTTP下载 |
| permission_handler | ^12.0.1 | 权限管理 |
| flutter_local_notifications | ^19.3.1 | 本地通知 |
| shared_preferences | ^2.3.2 | 本地存储 |
| file_picker | ^10.2.0 | 文件选择 |
| path_provider | ^2.1.2 | 路径获取 |

### Go依赖

项目依赖 [OpenList](https://github.com/OpenListTeam/OpenList) v4 核心库：
- `github.com/OpenListTeam/OpenList/v4/internal/bootstrap`
- `github.com/OpenListTeam/OpenList/v4/internal/db`
- `github.com/OpenListTeam/OpenList/v4/cmd`
- `github.com/OpenListTeam/OpenList/v4/internal/op`

---

## 项目运行方式

### 开发环境要求

- Flutter SDK >= 3.2.4
- Dart SDK >= 3.2.4
- Android SDK (Android开发)
- Xcode 15+ (iOS开发)
- Go 1.21+ (Go Mobile编译)
- Gomobile工具

### 构建流程

#### 1. 初始化Go Mobile

```bash
cd openlist-lib/scripts
./init_gomobile.sh
```

#### 2. 初始化OpenList依赖

```bash
./init_openlist.sh
```

#### 3. 编译Go库

```bash
./gobind.sh        # Android AAR
./gobind_ios.sh    # iOS Framework
```

#### 4. Flutter构建

```bash
flutter pub get
flutter build apk  # Android
flutter build ios  # iOS
```

### 运行调试

```bash
flutter run
```

### CI/CD流程

项目使用GitHub Actions自动化构建：

1. **build.yaml**: 开发版本构建
2. **release.yaml**: 发布版本构建
3. **sync_openlist.yaml**: 每日自动同步OpenList版本

---

## 关键类与函数索引

### Flutter层

| 文件 | 类/函数 | 说明 |
|------|---------|------|
| [main.dart](file:///workspace/lib/main.dart) | `main()` | 应用入口 |
| [main.dart](file:///workspace/lib/main.dart) | `MyApp` | 根Widget |
| [main.dart](file:///workspace/lib/main.dart) | `MyHomePage` | 主页面 |
| [openlist.dart](file:///workspace/lib/pages/openlist/openlist.dart) | `OpenListScreen` | 服务控制界面 |
| [openlist.dart](file:///workspace/lib/pages/openlist/openlist.dart) | `OpenListController` | 服务控制器 |
| [settings.dart](file:///workspace/lib/pages/settings/settings.dart) | `SettingsScreen` | 设置界面 |
| [service_manager.dart](file:///workspace/lib/utils/service_manager.dart) | `ServiceManager` | 服务管理器 |
| [download_manager.dart](file:///workspace/lib/utils/download_manager.dart) | `DownloadManager` | 下载管理器 |
| [native_bridge.dart](file:///workspace/lib/contant/native_bridge.dart) | `NativeBridge` | 原生桥接封装 |

### Android层

| 文件 | 类/函数 | 说明 |
|------|---------|------|
| [App.kt](file:///workspace/android/app/src/main/kotlin/com/openlist/mobile/App.kt) | `App` | Application类 |
| [OpenListService.kt](file:///workspace/android/app/src/main/kotlin/com/openlist/mobile/OpenListService.kt) | `OpenListService` | 后台服务 |
| [OpenList.kt](file:///workspace/android/app/src/main/kotlin/com/openlist/mobile/model/openlist/OpenList.kt) | `OpenList` | Go库调用封装 |
| [ServiceBridge.kt](file:///workspace/android/app/src/main/kotlin/com/openlist/mobile/bridge/ServiceBridge.kt) | `ServiceBridge` | 服务桥接 |
| [AppConfigBridge.kt](file:///workspace/android/app/src/main/kotlin/com/openlist/mobile/bridge/AppConfigBridge.kt) | `AppConfigBridge` | 配置桥接 |

### iOS层

| 文件 | 类/函数 | 说明 |
|------|---------|------|
| [OpenListManager.swift](file:///workspace/ios/Runner/OpenListManager.swift) | `OpenListManager` | OpenList管理 |
| [OpenListEventHandler.swift](file:///workspace/ios/Runner/OpenListManager.swift) | `OpenListEventHandler` | 事件处理 |
| [OpenListLogCallback.swift](file:///workspace/ios/Runner/OpenListManager.swift) | `OpenListLogCallback` | 日志回调 |

### Go层

| 文件 | 函数 | 说明 |
|------|------|------|
| [server.go](file:///workspace/openlist-lib/openlistlib/server.go) | `Init()` | 初始化 |
| [server.go](file:///workspace/openlist-lib/openlistlib/server.go) | `Start()` | 启动服务器 |
| [server.go](file:///workspace/openlist-lib/openlistlib/server.go) | `Shutdown()` | 关闭服务器 |
| [settings.go](file:///workspace/openlist-lib/openlistlib/settings.go) | `SetConfigData()` | 设置数据目录 |
| [settings.go](file:///workspace/openlist-lib/openlistlib/settings.go) | `SetAdminPassword()` | 设置管理员密码 |

---

## 国际化支持

项目支持中文和英文：

- 资源文件: [lib/l10n/intl_zh.arb](file:///workspace/lib/l10n/intl_zh.arb), [lib/l10n/intl_en.arb](file:///workspace/lib/l10n/intl_en.arb)
- 生成代码: [lib/generated/l10n.dart](file:///workspace/lib/generated/l10n.dart)
- 语言控制器: [lib/utils/language_controller.dart](file:///workspace/lib/utils/language_controller.dart)

支持三种语言模式：
1. 跟随系统
2. 简体中文
3. 英文

---

## 数据存储

### 配置存储

- **Android**: SharedPreferences
- **iOS**: UserDefaults
- **数据目录**: 用户可配置，默认应用私有目录

### OpenList数据

- 配置文件: `{dataDir}/config.json`
- 数据库: SQLite (WAL模式)
- 日志: 标准输出 + 文件日志

---

## 保活机制

### Android保活策略

1. **前台服务**: 显示常驻通知栏
2. **WakeLock**: 保持CPU唤醒（可选）
3. **START_STICKY**: 服务被杀后自动重启
4. **开机自启动**: BootReceiver监听系统启动
5. **电池优化白名单**: 提示用户关闭电池优化

### iOS策略

- iOS不支持前台服务，依赖系统管理
- 首次启动自动启动服务
- 使用后台任务保持运行

---

## 更新机制

### 自动更新检查

- 启动时检查（可配置）
- GitHub Releases API获取最新版本
- 显示更新对话框
- 下载APK/IPA并安装

### 自动同步构建

GitHub Actions每日早晚五点自动检查OpenList最新版本并构建发布。

---

## 安全考虑

1. **管理员密码**: 用户可自定义
2. **数据目录**: 用户可控
3. **权限管理**: 明确的权限请求流程
4. **电池优化**: 提示用户处理

---

## 故障排查

设置页面提供故障排查入口 ([lib/pages/settings/troubleshooting_page.dart](file:///workspace/lib/pages/settings/troubleshooting_page.dart))，包括：

- 电池优化设置引导
- 自启动设置引导
- 服务状态检查

---

## 扩展开发指南

### 添加新的原生API

1. 在 [pigeons/pigeon.dart](file:///workspace/pigeons/pigeon.dart) 定义API
2. 运行 `flutter pub run pigeon` 生成代码
3. 在Android/iOS实现API
4. 在Flutter调用

### 添加新页面

1. 在 `lib/pages/` 创建页面文件
2. 使用GetX进行状态管理
3. 在 `main.dart` 添加路由或导航

### 添加新配置项

1. 在AppConfig Pigeon API添加方法
2. 在AppConfigBridge/AppConfig实现存储
3. 在设置页面添加UI控件

---

## 参考链接

- [OpenList项目](https://github.com/OpenListTeam/OpenList)
- [Flutter官方文档](https://flutter.dev/)
- [Pigeon文档](https://pub.dev/packages/pigeon)
- [GetX文档](https://pub.dev/packages/get)
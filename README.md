# 🎵 音乐播放器 (Audio Player)

一款基于 Flutter 开发的 iOS 音频播放器，支持 iPhone 和 iPad。选择文件夹后自动扫描音频文件，提供完整的播放控制和定时关闭功能。

## ✨ 功能特性

### 📁 文件夹管理
- 选择本地文件夹，自动扫描所有音频文件
- 支持递归扫描子目录（可开关）
- 支持格式：MP3、WAV、FLAC、M4A、AAC、OGG、WMA、OPUS、AMR

### 🎵 播放控制
- 播放 / 暂停
- 上一首 / 下一首
- 进度条拖动调节
- 4 种播放模式：顺序播放、列表循环、单曲循环、随机播放

### ⏰ 定时关闭（睡眠定时器）
- 8 个预设时间：5/10/15/30/45/60/90/120 分钟
- 自定义时间：1 - 180 分钟滑块调节
- 两种结束行为：暂停播放 / 停止播放
- 实时倒计时显示
- 随时取消或调整

### 📱 自适应布局
- **iPhone**：单列列表 + 底部迷你播放栏
- **iPad**：左右分栏（播放列表 + 播放详情面板）
- 支持横竖屏切换

### 🔊 其他
- 后台播放支持
- 暗色主题设计

## 🚀 快速开始

### 环境要求
- Flutter SDK >= 3.10.0
- Xcode >= 14.0
- iOS 13.0+

### 安装运行

```bash
# 克隆项目
git clone <仓库地址>
cd audio_player

# 安装依赖
flutter pub get

# 运行到 iOS 模拟器或设备
flutter run

# 构建 Release 版本
flutter build ios --release
```

## 📁 项目结构

```
audio_player/
├── lib/
│   ├── main.dart                      # 应用入口 + 主题
│   ├── models/
│   │   └── audio_file.dart            # 音频文件模型
│   ├── services/
│   │   ├── audio_scanner_service.dart # 音频文件扫描服务
│   │   ├── audio_player_service.dart  # 播放控制服务
│   │   └── sleep_timer_service.dart   # 睡眠定时器服务
│   ├── widgets/
│   │   ├── audio_list.dart            # 播放列表组件
│   │   ├── player_bar.dart            # 底部播放控制栏
│   │   └── sleep_timer_dialog.dart    # 定时器设置对话框
│   └── pages/
│       └── home_page.dart             # 主页面
├── ios/
│   ├── Runner/                        # iOS 原生代码
│   ├── Runner.xcodeproj/              # Xcode 项目
│   ├── Runner.xcworkspace/            # Xcode 工作区
│   ├── Flutter/                       # Flutter 配置
│   └── Podfile                        # CocoaPods 依赖
└── pubspec.yaml                       # Flutter 依赖配置
```

## 🎨 设计说明

- 使用 `provider` 进行状态管理
- 使用 `just_audio` 作为音频播放引擎
- 使用 `file_picker` 进行文件夹选择
- 使用 `audio_session` 配置音频会话
- 暗色主题，紫色为主色调

## 📝 注意事项

1. 首次运行需要执行 `flutter pub get` 安装依赖
2. iOS 端需要执行 `cd ios && pod install` 安装原生依赖
3. `ios/Flutter/Generated.xcconfig` 由 Flutter 自动生成，首次构建时会更新
4. 如需修改应用包名，修改 `ios/Runner.xcodeproj/project.pbxproj` 中的 `PRODUCT_BUNDLE_IDENTIFIER`

## 📄 License

MIT

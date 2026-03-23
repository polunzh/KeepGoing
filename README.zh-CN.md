<p align="center">
  <img src="Screenshots/keepgoing-logo.png" width="320" alt="KeepGoing Logo">
</p>

<h1 align="center">KeepGoing</h1>

<p align="center">一个为当前阶段设计的 macOS + iOS 提醒应用。</p>

<p align="center">
  <img src="Screenshots/keepgoing.png" width="800" alt="KeepGoing 截图">
</p>

## 已实现

- `macOS` 常规窗口：管理和编辑提醒内容
- `macOS` 菜单栏入口：可显示、隐藏悬浮提醒窗
- `macOS` 悬浮提醒窗：常驻最上层，整体作为日进度条，随时段变化色温
- `iOS` 编辑界面：和 macOS 共享同一套提醒编辑逻辑
- 本地持久化：提醒内容、当前选中项、轮播间隔会保存在本地

## 安装

从 [Releases](../../releases/latest) 下载最新 DMG，打开后将 KeepGoing 拖到 Applications。

如果 macOS 提示无法打开，在终端执行：

```bash
xattr -cr /Applications/KeepGoing.app
```

## 从源码构建

1. 用 Xcode 打开 `KeepGoing.xcodeproj`
2. 选择 `KeepGoing_macOS` 运行到 Mac
3. 选择 `KeepGoing_iOS` 运行到 iPhone Simulator

## 这版的边界

- 还没有接入 `iCloud` 同步
- 还没有 `Widget`
- 还没有系统通知和定时提醒

## 适合下一步加的功能

- `iCloud / CloudKit` 同步
- `macOS / iOS Widget`
- 每日固定时间自动切换提醒
- 从你的 Obsidian 日记自动导入一句"今日提醒"

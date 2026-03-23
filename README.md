<p align="center">
  <img src="Screenshots/keepgoing-logo.png" width="320" alt="KeepGoing Logo">
</p>

<h1 align="center">KeepGoing</h1>

<p align="center">A macOS + iOS reminder app designed for the current stage.</p>

<p align="center">
  <a href="README.zh-CN.md">中文说明</a>
</p>

<p align="center">
  <img src="Screenshots/keepgoing.png" width="800" alt="KeepGoing Screenshot">
</p>

## Features

- **Floating panel** — always-on-top widget with two sizes: standard (280x130) and mini (self-adaptive width, single line). The entire panel is a day progress bar
- **Time awareness** — ticking seconds, day progress percentage, smooth sun-journey color tinting that follows the real clock (dawn purple → sunrise orange → noon clear → sunset red → night blue, 18 anchor points with continuous interpolation)
- **3 animation effects** — breath glow (heart pulse), progress pulse (boundary glow), particle drift (smooth 60fps hourglass sand). User selectable
- **256 color palettes** — hue-based color system with 16x16 grid picker
- **Auto update check** — checks GitHub Releases on launch, prompts to download new versions
- **Carousel rotation** — auto-cycle through reminders at configurable intervals
- macOS main window for managing and editing reminders
- macOS menu bar entry for quick access
- iOS editing with shared reminder logic
- Local persistence for all settings

## Install

Download the latest DMG from [Releases](../../releases/latest). After opening the DMG, drag KeepGoing to Applications.

If macOS blocks the app, run in Terminal:

```bash
xattr -cr /Applications/KeepGoing.app
```

## Build from Source

1. Open `KeepGoing.xcodeproj` in Xcode
2. Select `KeepGoing_macOS` to run on Mac
3. Select `KeepGoing_iOS` to run on iPhone Simulator

## Current Limitations

- No iCloud sync yet
- No Widget yet
- No system notifications or scheduled reminders yet

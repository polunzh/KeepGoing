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

- macOS main window: manage and edit reminders
- macOS menu bar entry: show/hide the floating reminder panel
- macOS floating panel: always-on-top with day progress visualization and time-of-day color tinting
- iOS editing: shares the same reminder editing logic as macOS
- Local persistence: reminders, current selection, and rotation interval are saved locally

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

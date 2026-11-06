<div align="center">
  <img src="https://raw.githubusercontent.com/OpenListTeam/Logo/main/logo.svg" height="100px" alt="OpenList Logo">
  <h1>OpenList-Mobile</h1>
</div>


<div align="center">

[![Release](https://github.com/OpenListTeam/OpenList-Mobile/actions/workflows/release.yaml/badge.svg)](https://github.com/OpenListTeam/OpenList-Mobile/actions/workflows/release.yaml)
[![Build](https://github.com/OpenListTeam/OpenList-Mobile/actions/workflows/build.yaml/badge.svg)](https://github.com/OpenListTeam/OpenList-Mobile/actions/workflows/build.yaml)
[![Sync OpenList](https://github.com/OpenListTeam/OpenList-Mobile/actions/workflows/sync_openlist.yaml/badge.svg)](https://github.com/OpenListTeam/OpenList-Mobile/actions/workflows/sync_openlist.yaml)
[![License](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.32.7-blue.svg)](https://flutter.dev/)
[![OpenList](https://img.shields.io/github/v/release/OpenListTeam/OpenList?label=OpenList)](https://github.com/OpenListTeam/OpenList)

</div>

<div align="center">
  <a href="README.md">🇨🇳 中文</a> | <a href="README_EN.md">🇺🇸 English</a>
</div>


**OpenList-Mobile** is a mobile file server application based on [OpenList](https://github.com/OpenListTeam/OpenList), built with Flutter framework. Turn your phone into a powerful file server with LAN file sharing, remote access, and online management capabilities.

### Download & Installation

#### Stable Release
- [📱 Latest Release](https://github.com/OpenListTeam/OpenList-Mobile/releases/latest) - Recommended

#### Development Build
- [🔧 Development Build](https://github.com/OpenListTeam/OpenList-Mobile/actions/workflows/build.yaml) - Latest Features

> **Auto-Update**: [GitHub Actions](https://github.com/OpenListTeam/OpenList-Mobile/actions/workflows/sync_openlist.yaml) automatically checks for the latest [OpenList](https://github.com/OpenListTeam/OpenList/releases) version twice daily (5 AM & 5 PM) and builds releases, ensuring always have access to the latest version.

### Supported Platforms
- Android
- iOS (Experimental, still in development)

### Android background behavior
Background operation is controlled by Android and device-vendor policies; OpenList cannot guarantee that it will remain active indefinitely. Boot recovery is attempted only when enabled in the app, and battery optimization, vendor auto-start controls, or background restrictions may prevent recovery or stop the service. Android does not automatically restart an app after the user force-stops it. On Android 13 and later, notification permission affects how the foreground-service notification is shown and managed. To use the background server, do not force-stop the app and review the device's battery and auto-start settings.

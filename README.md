

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


**OpenList-Mobile** 是一个基于 [OpenList](https://github.com/OpenListTeam/OpenList) 的移动端文件服务器应用，使用 Flutter 框架开发。支持局域网文件共享、远程访问和在线管理。

### 下载安装

#### 稳定版本
- [📱 发布版](https://github.com/OpenListTeam/OpenList-Mobile/releases/latest) - 推荐使用

#### 开发版本
- [🔧 构建版](https://github.com/OpenListTeam/OpenList-Mobile/actions/workflows/build.yaml) - 最新功能

> **自动更新**：[GitHub Actions](https://github.com/OpenListTeam/OpenList-Mobile/actions/workflows/sync_openlist.yaml) 每日早晚五点自动检查最新的 [OpenList](https://github.com/OpenListTeam/OpenList/releases) 版本并构建发布，确保始终使用最新版本。


### 支持平台
- Android
- iOS (实验性，仍在开发)

### Android 后台运行说明
Android 的后台运行由系统和设备厂商策略管理，不能保证 OpenList 始终在后台运行。开机自动启动仅在应用内启用后尝试恢复；电池优化、厂商自启动管理和后台限制可能阻止恢复或终止服务。用户强制停止应用后，系统不会自动重新启动服务。Android 13 及以上的通知权限会影响前台服务通知的显示与管理。需要后台服务时，请保持应用未被强制停止，并按设备系统设置查看电池和自启动限制。

# 说明

一个基于 Flutter 的天气应用，使用 Open-Meteo 接口获取指定经纬度的天气信息。设计理念：极简、消除老年人阅读障碍。

我感到非常抱歉，第一次安装时需要输入经纬度，对于老年人来说太麻烦了，可以让家人来帮忙。

## 项目简介

应用启动后会先读取本地保存的经纬度：如果已经保存过位置，直接进入天气主页；如果没有，则先进入首次设置页填写纬度和经度。天气主页只展示今天和明天，并将逐时天气数据聚合为上午、下午、6 小时分组和 2 小时分组视图。

## 功能

- 启动时检查本地是否已有经纬度
- 首次使用时手动填写纬度和经度
- 支持修改并重新保存当前位置
- 调用 Open-Meteo 获取天气数据
- 展示今天和明天的天气摘要
- 将逐时数据聚合为上午、下午、6 小时和 2 小时视图
- 网络失败或启动失败时显示空白错误页，并支持重试

## 技术栈

- Flutter
- http
- shared_preferences

## 运行环境

- Flutter SDK 3.12 或更高版本
- Android Studio、VS Code 或其他支持 Flutter 的开发环境

## 快速开始

安装依赖：

```bash
flutter pub get
```

运行应用：

```bash
flutter run
```

执行静态检查：

```bash
flutter analyze
```

运行测试：

```bash
flutter test
```

## 使用说明

1. 首次启动时，输入纬度和经度并保存。
2. 保存后进入天气主页，应用会根据当前位置请求天气数据。
3. 在天气主页右上角点击设置按钮，可以修改经纬度并立即刷新天气。

## 目录结构

```text
lib/
  main.dart                    # 程序入口
  app/weather_app.dart         # 应用根组件与主题
  core/location/               # 经纬度模型、校验与本地存储
  core/weather/                # Open-Meteo 请求、模型与天气聚合
  features/startup/            # 启动分流
  features/location/           # 经纬度设置页
  features/weather/            # 天气主页
  features/error/              # 空白错误页
```

## 设计说明

- 启动层负责分流，不直接承载天气请求逻辑
- 经纬度通过 `shared_preferences` 持久化到本地
- 天气主页只关注展示和刷新，不负责数据聚合细节
- 错误页保持极简，只提供重试入口


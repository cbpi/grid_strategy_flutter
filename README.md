# 网格策略 App

独立 Flutter 工程，用于 iOS 和 Android。当前首版已迁移网页网格策略面板的核心能力：

- A 股标的切换与新增
- 公开行情刷新、日 K 和 MA20
- 持仓、成本价和一键粘贴录入
- 网格买卖价位计算
- 仓位建议器
- 买卖成交记录、策略日志和每日快照
- 使用 `shared_preferences` 保存本地数据

## 开发运行

```bash
cd grid_strategy_app
flutter pub get
flutter run
```

## 构建

```bash
flutter build apk --debug
flutter build apk --release
flutter build ios --no-codesign
```

## 行情说明

原项目的 `stock-sdk` 是 JavaScript/npm 依赖，不能直接被 Dart 原生工程引用。本 App 使用 Dart `http` 适配同类公开行情接口，账户、日志和快照仍保存在设备本地。行情接口是公开市场数据，存在延迟和网络失败可能，不应作为唯一下单依据。

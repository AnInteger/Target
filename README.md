# Target · 生活目标守护

单用户生活目标记录 App（Flutter，iOS 优先，Web 为全功能验证面）——记录为目标做过的每一次努力：今日打卡、周节奏回顾、场景化提醒、本地备份。数据只在这台设备上，不上传、不联网。

## 常用命令

```sh
export PATH="/home/sunxing/development/flutter/bin:$PATH"
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

flutter analyze && flutter test   # 质量门禁
flutter run -d chrome             # 日常验证主面（IndexedDB 持久化）
flutter build web --release       # 产物在 build/web（本地起服务无头走查）
git push                          # 发布到远端；iOS 构建为 Codemagic 手动触发（ios-unsigned → unsigned.ipa → iLoader 自签装机，无 TestFlight 链路）
```

## 结构要点

- `lib/` — App 代码。设计令牌唯一真源 `lib/app/design_tokens.dart`：CSS 镜像 `design/tokens.css`、iOS 小组件镜像 `ios/TargetWidgets/DesignTokens.swift`，改色一次提交内三端同步
- `design/` — 原型先行流程：`prototypes/`（HTML 高保真原型，`index.html` 为评审入口）、`tokens.css`、`reviews.md`（评审记录；某屏结论为「通过」前不进实现，FR-001）
- `specs/` — Spec Kit 特性目录（001 基础功能 / 002 UI/UX 全面重设计）；跨特性契约在 `specs/contracts/`（设计语言、原型评审）
- `ios/TargetWidgets/` — WidgetKit 小组件（纯渲染；数据经 App Group 快照由 Dart 侧写入）

## 导航与目标模型（2026-08-26 phase 1）

- **三个主 tab**：底部 dock = 今日 | 目标 | 进展（中央 FAB 已退役；新建入口在目标页头部）。我的/设置/编辑器/详情为全屏推入页，进入后隐藏 dock
- **统一目标规划**：目标名是唯一必填项；目标日期、执行节奏（每天/每周 N 次/指定星期）、里程碑、分类、提醒均为可选且可任意组合，互不排斥
- **可逆生命周期**：进行中 ⇄ 已暂停、标记达成 ⇄ 重新打开、归档 ⇄ 取消归档（归档保留全部打卡与里程碑，仅从今日/统计/提醒/小组件中隐去）；删除为独立确认的破坏性操作
- **数据层**：schema v7（goals 增加 `frequency_pattern`、`archived_at`，旧列保留兼容）；备份格式版本 6（v1–v5 旧备份可无损导入）；迁移测试覆盖 v1→v7 全链路

> 注：今日页卡片、目标详情归属与简化记录流属 phase 2；回顾时间线与 Profile/设置/通知清理属 phase 3——以上尚未实现，勿在此文档描述为现状。

## 验证指南

各特性验收场景见 `specs/<feature>/quickstart.md`：001 的 V1–V8 为功能回归底线，002 阶段 A/B/C 为 原型评审 → 实现回归 → 真机收尾。

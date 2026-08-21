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

## 验证指南

各特性验收场景见 `specs/<feature>/quickstart.md`：001 的 V1–V8 为功能回归底线，002 阶段 A/B/C 为 原型评审 → 实现回归 → 真机收尾。

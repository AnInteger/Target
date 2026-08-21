# Quickstart: UI/UX 全面重设计（验证指南）

按特性推进阶段给出可执行的验证场景。逐屏走查场景与 [001 的 quickstart](../001-life-goal-tracker/quickstart.md) 的 V1–V8 复用（功能回归底线），本文只列本特性新增的验证点。

## 前置

```sh
export PATH="/home/sunxing/development/flutter/bin:$PATH"
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

无 Mac 环境；iOS 真机经 Codemagic（push 触发 ios-testflight → TestFlight）。Web 为本地全功能验证面。

## 阶段 A：原型评审（每屏/每方向）

```sh
cd design && python3 -m http.server 8390   # 或直接 file:// 打开 HTML
```

浏览器开 `http://localhost:8390/prototypes/index.html`（或直接打开 `design/prototypes/index.html`）。

| 验证点 | 对应 | 预期 |
|---|---|---|
| 风格方向对比页可看、可切换 | FR-009 | ≥2 个方向同屏对比，选定后记录进 reviews.md |
| 各屏原型覆盖典型态 + 边界态 | 契约 prototype-review.md §1 | 空/深色至少其一可见（忙碌态 2026-08-21 裁决移除） |
| 编辑器原型含定义模型候选对比 | FR-010 / US3 | 2–3 个字段集方案，可据实选择 |
| 打卡动线原型可点击演示反馈 | FR-004 | 点击出反馈动效，成就时刻有独立呈现 |

## 阶段 B：逐屏实现后的回归（每屏收尾）

```sh
flutter analyze && flutter test          # 0 issue；既有 53+ 用例全绿
flutter test test/design/token_contract_test.dart   # 令牌契约（SC-004）
```

```sh
flutter build web --release && (cd build/web && python3 -m http.server 8321)
```

| 验证点 | 对应 | 预期 |
|---|---|---|
| 001 的 V1–V8 场景在新 UI 下重走 | FR-005 / SC-003 | 全部通过，数据刷新后保留 |
| 打卡主路径计时 | FR-003 / SC-002 | 打开 App → 完成一次打卡 ≤2 次交互 |
| 新旧风格并存屏数 | SC-006 | ≤1（走查各屏观感一致） |
| 深色模式切换 | FR-006 / SC-005 | 全屏可读，正文对比度达标 |
| 既有目标（无新维度字段）呈现 | data-model §1 | 渐进补全入口出现，不强制填写 |
| 数据零丢失 | FR-005 | 升级前后打开 App，既有目标/打卡/记录完整 |

无头走查提示（延续 001 技巧）：WebGL 必死时强制 `flt-semantics-placeholder` 可见并派发指针事件开启 semantics DOM 后用 a11y 驱动；长按路径用 widget 测试覆盖。

## 阶段 C：品牌与真机（收尾）

1. `design/brand/` 母版 → `dart run flutter_launcher_icons` / `dart run flutter_native_splash` → iOS 资产生成
2. 小组件视觉与主 App 并排核对（深浅两态）
3. `git push` → Codemagic 绿 → TestFlight 安装，真机核对：图标/启动屏、小组件（仅视觉，FR-008）、深色模式、打卡动效帧率（肉眼顺滑）、通知文案语气与按目标设定的提醒时机（FR-012，真机独占）
4. 备份回归：新 UI 下导出 → 导入覆盖 → 数据一致（含新维度字段）

## 完成口径

SC-001–SC-006 逐条核对；`design/reviews.md` 中全部核心屏结论为"通过"；tasks.md 全部勾完。

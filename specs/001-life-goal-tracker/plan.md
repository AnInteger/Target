# Implementation Plan: 生活目标守护 iOS App（Target）

**Branch**: `001-life-goal-tracker` | **Date**: 2026-08-18（Flutter 重规划版） | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-life-goal-tracker/spec.md`（含 2026-08-18 开发环境决策：WSL 开发、无 Mac、Codemagic 打包、Flutter 跨平台、Android 为 v1 后计划）

## Summary

一个极简、本地优先的 iPhone 目标管理应用：以"今日视图 + 生活电量"为视觉核心的习惯/里程碑双类型目标管理，配合桌面与锁屏小组件（可直接打卡）、周一晨结算的周回顾、忙碌模式（降档不熄火）与导出/导入备份闭环。技术栈为 **Flutter/Dart**：纯 Dart 的领域模型与统计引擎（连击/完成率/生活电量/周结算）独立于 UI，可在 WSL 宿主机直接跑测试；日常验证在**全功能 Web 端**进行（浏览器真实持久化，iOS 专属能力占位说明），push 即触发 Codemagic 构建 iOS（含原生 WidgetKit 小组件孤岛）并自动分发 TestFlight、由用户 iPhone 实机验收。v1 仅发布 iOS，架构保持跨平台可移植（Android 为 v1 后第一个扩展目标）。

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel（SDK 版本经 `fvm` 或团队锁定于 `pubspec.yaml` + `flutter --version` 约定）

**Primary Dependencies**（Flutter 无"纯系统框架"路线，以下均为该能力的事实标准包，逐一见 research.md D5）：
- `flutter_riverpod` — 状态管理与依赖注入
- `drift` + `sqlite3_flutter_libs` + `path_provider` — 本地 SQLite 持久化（支持流式查询与宿主机测试）
- `home_widget` — 桌面/锁屏小组件桥接（iOS 17 交互式小组件 + App Group 共享数据）
- `flutter_local_notifications` — 目标提醒与每日概要
- `go_router` — 导航与 `target://` 深链
- `share_plus` / `file_picker` — 备份导出分享 / 导入选择
- `clock`（dev 主力、prod 注入）— 可注入时钟，时间旅行测试
- dev: `drift_dev` + `build_runner`、`flutter_test`、`integration_test`

**Storage**: drift（SQLite）。iOS 上数据库文件置于 App Group 容器目录，主 isolate 与小组件后台回调 isolate 共进程访问；Android 走应用私有目录；**Web 端经 drift WasmDatabase（IndexedDB）持久化**——全功能本地验证的数据基座（research D3/D15）

**Testing**: `flutter test`（统计引擎 R1–R9、备份格式、FrequencyVersion 口径——纯 Dart，WSL 宿主机秒级回归）+ 全功能 Web 人工走查（日常验证主面，补签/周回顾/忙碌模式/备份闭环均在浏览器可验）+ TestFlight 真机验收 iOS 专属路径（小组件、系统通知、深链，见 research.md D15）

**Target Platform**: iOS 17.0+（交互式小组件打卡的硬门槛），iPhone 专属发布；Android 保持可构建（默认 minSdk），但不在 v1 发布范围、亦非本地验证面；**Web 为本地验证主面且须全功能可用**（真实持久化；提醒页内模拟；小组件等 iOS 专属能力占位说明，见 D15），不发布

**Project Type**: mobile-app（纯单机，无服务端、无网络依赖；Flutter 跨平台单代码库 + 极小 iOS 原生孤岛）

**Performance Goals**: 冷启动至可打卡 < 1.5s（Flutter 引擎启动余量）；打卡落库 < 100ms；今日视图 60fps；小组件 timeline 按系统节奏刷新（每日边界 + 数据变更后主动 reload）

**Constraints**: 完全离线可用；数据仅存设备本地；通知权限被拒时全功能降级可用（FR-007）；**开发环境硬约束**——无 Mac、WSL 日常开发、iOS 一切构建/签名/分发经 Codemagic；跨平台可移植（业务逻辑零 `dart:io`/平台通道直接耦合，平台能力一律经接口注入）

**Scale/Scope**: 单用户；活跃目标 ≤5、归档不限；记录量级 ~5 目标 × 365 天 × 数年 ≈ 万级 CheckIn（SQLite 轻松承载）；6 个主界面（今日、目标管理/编辑、里程碑详情、周回顾、忙碌模式、设置）+ 1 个原生小组件扩展

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` 为未填写的模板（全部占位符），项目尚未批准任何宪法原则——**无门禁可评估**。本计划以规格的 FR/SC 与 `checklists/requirements.md`（16/16 通过）作为替代门禁。

**Post-Phase-1 re-check**: 设计产物（research.md / data-model.md / contracts/）与规格 18 条 FR 逐一对齐，未发现违规；无需 Complexity Tracking 条目。待宪法正式批准后（`/speckit-constitution`），需回头补检。

## Project Structure

### Documentation (this feature)

```text
specs/001-life-goal-tracker/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   ├── stats-engine.md      # 统计计算契约（连击/完成率/电量/结算）
│   ├── backup-format.md     # 备份文件格式契约
│   ├── widget-intent.md     # 小组件与打卡交互契约（含 home_widget 桥接）
│   └── ui-contract.md       # 界面与导航契约
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root = Flutter 项目根)

```text
.
├── pubspec.yaml                 # Flutter 项目清单（依赖锁定）
├── lib/
│   ├── main.dart                # 入口：ProviderScope、通知注册、小组件回调注册
│   ├── app/                     # MaterialApp、go_router 路由、主题设计令牌
│   ├── core/
│   │   ├── models/              # 领域模型（纯 Dart，无 Flutter/平台依赖）
│   │   ├── stats/               # 统计引擎：连击/完成率/生活电量/周结算（纯函数）
│   │   ├── backup/              # 备份导出/导入（版本化 JSON，纯 Dart 可测）
│   │   ├── db/                  # drift 数据库 schema 与仓库层（唯一平台数据出入口）
│   │   ├── platform/            # 平台能力接口（通知/小组件/分享/文件）+ iOS/Android/Web 实现
│   │   │                        #   （Web：浏览器下载导出、文件选择导入、页内提醒模拟）
│   │   └── copy.dart            # 全局文案表（语气集中审校，ui-contract）
│   └── features/
│       ├── today/               # 今日视图：生活电量 + 今日目标列表 + 打卡
│       ├── goals/               # 目标管理、创建/编辑、模板库、SMART 引导
│       ├── milestones/          # 里程碑详情：步骤、倒计时、进度
│       ├── review/              # 周回顾（周一晨结算呈现）
│       ├── busy_mode/           # 忙碌模式开启/恢复
│       └── settings/            # 提醒、备份导出/导入、数据风险明示、Debug 时钟
├── ios/
│   ├── Runner/                  # Flutter iOS 宿主（App Group 能力声明）
│   └── TargetWidgets/           # 原生孤岛：WidgetKit 扩展（Swift，2–3 文件）
│       ├── TodayWidgetBundle.swift   # small/medium/锁屏 families + timeline
│       └── (交互回调由 home_widget 提供，无需自写 App Intent)
├── android/                     # 保持可构建（v1 不发布）
├── test/                        # 纯 Dart 单元测试（统计/备份/口径——WSL 宿主机可跑）
└── codemagic.yaml               # push 触发：iOS 构建 + 小组件扩展 + 绿即自动 TestFlight 分发
```

**Structure Decision**:
1. **仓库根即 Flutter 项目根**——`flutter test`/`flutter run` 直接可用，specs/ 与 .specify/ 共存无冲突。
2. **领域/统计/备份纯 Dart 且零 Flutter 依赖**（`core/models|stats|backup`）——这是跨平台可移植假设的落点，也是 WSL 无模拟器环境下测试密度的落点；平台能力（通知、小组件、分享）全部收口在 `core/platform/` 接口后，UI 与业务逻辑只面向接口。
3. **原生孤岛最小化**——iOS 小组件是 Flutter 无法渲染的唯一部分，压缩为一个 WidgetKit 扩展目录；其数据由 Dart 侧经 home_widget 写入 App Group 共享存储，交互回调在后台 isolate 中执行**同一套 Dart 打卡逻辑**（与主 App 同一仓库层、同一统计引擎），避免两份业务实现（详见 [widget-intent.md](./contracts/widget-intent.md)）。
4. **Codemagic 承担全部 iOS 侧**——`codemagic.yaml` 与仓库共生，push 即构建、绿即自动 TestFlight（CI 门禁，2026-08-18 用户决策）；iOS 构建问题的第一发现点在 CI 而非本地。
5. **Web 是验证面而非发布面**——全功能 Web（真实持久化 + 平台能力的 Web 实现/模拟）只为让数据闭环在浏览器可走查；产品发布仍仅 iOS，Web 不进发布范围。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

无违规，不适用。

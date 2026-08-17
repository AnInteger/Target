# Research: 生活目标守护 iOS App（Target）

**Feature**: `specs/001-life-goal-tracker` | **Date**: 2026-08-18（Flutter 重规划版）
**Input**: [spec.md](./spec.md)（18 条 FR、7 条 SC、11 条已确认决策，含 2026-08-18 开发环境决策）

所有 Technical Context 中的技术未知项在本文档以「决策 / 理由 / 备选」格式解决。无遗留 NEEDS CLARIFICATION。

---

## D1. 框架与语言

- **决策**: Flutter + Dart 3（stable channel）
- **理由**: 硬约束驱动的唯一可行解——开发机为 WSL 且无 Mac，原生 iOS（SwiftUI）没有可用的本地开发循环，每次迭代都要走一轮 CI；Flutter 提供 WSL 本地循环（Android 设备/模拟器 + Web 目标），iOS 构建交 Codemagic；同时满足"Android 为 v1 后计划"的跨平台约束（业务逻辑单代码库）。
- **备选**: 原生 SwiftUI（无 Mac = 死路）→ 弃；React Native（跨平台可行，但小组件/原生桥接生态与个人维护成本劣于 Flutter）→ 弃。

## D2. 部署目标

- **决策**: iOS 17.0+（iPhone 专属发布）；Android 保持可构建（默认 minSdk）但不在 v1 发布
- **理由**: SC-007 要求小组件直接打卡——iOS 17 起按钮才能在 WidgetKit 内触发交互（`HomeWidgetBackgroundIntent` 路径），这是唯一硬门槛，与应用其余能力无冲突，直接取 17。Android 端代码保留构建通过，为 v1 后扩展省一次骨架迁移。
- **备选**: iOS 16（小组件打卡必须跳转 App，违反 FR-016"无需打开应用主体"）→ 弃。

## D3. 本地存储

- **决策**: drift（SQLite ORM）+ `sqlite3_flutter_libs`；iOS 上数据库文件置于 App Group 容器目录；**Web 端走 WasmDatabase（IndexedDB 持久化）**，支撑全功能 Web 本地验证（2026-08-18 决策：Web 为本地验证主面，刷新/重开不丢数据）
- **理由**: ① 结构化查询与流式响应（今日视图随打卡即时刷新）；② **宿主机可测**——drift 支持 Dart VM 内存库，统计/仓库测试在 WSL 直接 `flutter test`，不依赖模拟器（对无 Mac 环境至关重要）；③ 万级 CheckIn 对 SQLite 无压力；④ 小组件后台回调 isolate 与主 isolate 同进程，App Group 路径下可安全并发访问（SQLite WAL）；⑤ 同一套仓库层经平台条件初始化即可跑在 Web（IndexedDB），使补签/周回顾/忙碌模式等数据闭环全部可在浏览器走查。
- **备选**: Isar（性能好但 v3 维护停滞、v4 未稳）；Hive（键值模型，结构化查询全手写）；sqflite（无桌面/宿主机测试路径）→ 均弃。

## D4. 状态管理

- **决策**: flutter_riverpod（Provider 体系 + 依赖注入）
- **理由**: 编译期安全、天然可测（ProviderContainer 覆写注入仓库/时钟）、与 drift Stream 组合成响应式 UI 的路径最短；同时充当应用的依赖注入容器（平台接口、DateProvider 均经 Provider 注入）。
- **备选**: Bloc（样板多、口径类简单状态收益低）；setState/Provider（测试与注入能力弱）→ 弃。

## D5. 第三方依赖策略

- **决策**: 放弃"零依赖"（Swift 版的旧约束），改用**白名单制**：`flutter_riverpod`、`drift`+`sqlite3_flutter_libs`+`path_provider`、`home_widget`、`flutter_local_notifications`、`go_router`、`share_plus`、`file_picker`、`clock`。新增依赖须在 research.md 补决策条目。
- **理由**: Flutter 不存在"纯系统框架"路线——上述每一项对应一个系统能力（存储/小组件/通知/分享），且均为社区事实标准、维护活跃；控制手段从"零"改为"白名单 + 逐项决策留痕"。
- **备选**: 坚持 0 依赖（则需自写 SQLite FFI、通知通道、分享通道等数千行平台代码——恰恰是最难在无 Mac 下维护的部分）→ 弃。

## D6. 时间逻辑与可测性

- **决策**: 业务与统计代码只读注入的时钟（`clock` 包的 `clock.now()`，生产环境默认实现）；自然日按设备本地时区的当日零点换算；周 = 周一至周日
- **理由**: 跨天打卡归属、周一结算、连击计算全部依赖"今天是哪天"，必须可时间旅行测试（规格 Edge Cases 明确 23:59/00:01 归属）。开发构建内建 Debug 时钟调试菜单（设置页）用于真机验证周结算。
- **备选**: 直接 `DateTime.now()` 散落各处（不可测）→ 弃。

## D7. 频率的生效期建模（本设计最关键的数据决策）

- **决策**: 习惯频率建模为**带生效周的历史版本**（`FrequencyVersion`，`effectiveFromWeek` = 周一日期）：用户改频率 → 追加"下周一生效"版本（FR-002）；忙碌模式 → 插入"本周"临时版本、恢复时移除（FR-018）。任一天的有效频率 = 该日所在周的最新版本。
- **理由**: 规格两条规则（下一周期生效 / 忙碌当周生效并恢复）本质都是"频率随时间分段"，版本化让结算永远按"当时的约定"计算，统计口径天然稳定、无需回溯重算（直接支撑 FR-002 与 SC-003）。
- **备选**: 单一字段 + 修改时间戳（结算需按时间轴重建口径，复杂且易错）；忙碌模式另建平行字段（两套口径合并处必出 bug）→ 均弃。

## D8. 备份格式

- **决策**: 单个版本化 JSON 文件（`format: "target-backup"`，`version: 1`），自定义扩展名 `.targetbackup`；导出走系统分享面板（`share_plus`），导入走文件选择器（`file_picker`）；导入冲突提示"覆盖本地 / 取消"，不静默合并（FR-015）
- **理由**: dart `json_serializable`/手写序列化即可完成，人可读、可 diff、可被未来版本迁移；单文件降低用户操作成本。iOS 侧声明自定义 UTType（`com.target.backup`）以便系统识别。
- **备选**: CSV（丢失结构）、SQLite 快照（黑盒、版本迁移难）、iCloud 文档（超出本地优先决策）→ 弃。格式契约见 [backup-format.md](./contracts/backup-format.md)。

## D9. 生活电量 v1 合成公式

- **决策**: `生活电量 = mean(各活跃习惯目标当日完成度) × 100`，其中单目标当日完成度 = `min(当日有效打卡次数 / 当日目标次数, 1)`；按当日有效频率（含忙碌降档）计算；**里程碑目标不参与电量**；无活跃习惯目标时显示空态"—"而非 0
- **理由**: 语义直白（"今天为自己做到几成"）、忙碌模式自动按降档口径（与周结算一致）、无需调参；里程碑无每日行为，计入只会稀释或虚高。公式属派生计算不落库（FR-017）。
- **备选**: 按周滚动均值（更平滑但当日反馈迟钝）；加权（近期目标权重高，需调参且解释成本高）→ 留待 v1.1 依据真实使用感受再评估。

## D10. 连击（streak）口径

- **决策**: 连击 = 截至今天，**连续的"适用日且达标"**天数；非适用日（每周 3 次的自由分布、指定星期几的休息日）跳过、不断链；昨天未达标但从今天起达标 = 从 1 重新计；补签计入对应日（可将断链"接回"，但周回顾呈现补签次数，透明可查）
- **理由**: "每周 3 次"类目标若按自然日算断链，永远不可能有长连击，激励失效；跳过非适用日是习惯类产品的通行口径。
- **备选**: 严格自然日连击（对自由分布目标不公平）→ 弃。

## D11. 周回顾的数据口径

- **决策**: 回顾页**展示时实时重算**（因补签可改写历史，FR-004），同时**归档结算快照**（周一晨生成时的各目标统计存入 `WeeklyReview`）
- **理由**: 兼顾"如实呈现补签后的最新事实"与"历史结算留痕"；实时重算复用统计引擎同一纯函数，无一致性风险。
- **备选**: 只存快照（补签后数据失真）；只实时算（无历史留痕）→ 均弃。

## D12. 测试策略

- **决策**: 分三层。① `test/`：统计引擎 R1–R9 逐条 + 备份格式 + FrequencyVersion 口径 + 仓库层（drift 内存库）——**纯 Dart，WSL 宿主机 `flutter test` 秒级回归，为主力**；② 全功能 Web（`flutter run -d chrome`）：日常人工验证主面，补签/周回顾/忙碌模式/备份等数据闭环在浏览器走查（2026-08-18 决策）；③ TestFlight 真机人工验收：iOS 专属路径（小组件、系统通知、深链），按 quickstart.md 场景在用户 iPhone 上逐条执行
- **理由**: 复杂度集中在口径计算而非 UI；无 Mac 环境下必须让绝大多数回归发生在宿主机纯 Dart 层与 Web 面，iOS 真机只验平台专属行为。
- **备选**: 全 UI/集成测试（慢、脆、依赖模拟器，WSL 下成本高）→ 弃。

## D13. 小组件桥接（Flutter ↔ WidgetKit）

- **决策**: `home_widget` 桥接。数据路径：数据每次变更后，Dart 侧把**今日快照**（生活电量 + 各目标名称/颜色/当日 x/y）经 `HomeWidget.saveWidgetData` 写入 App Group 共享存储，并触发 timeline 刷新；小组件 Swift 侧只读快照渲染。交互路径：iOS 17 交互式按钮触发 `HomeWidgetBackgroundIntent` → 在后台 isolate 中执行**同一套 Dart 打卡逻辑**（同一仓库层与统计引擎）→ 重写快照。原生孤岛压缩为 2–3 个 Swift 文件（timeline + 布局）。
- **理由**: 打卡口径（R1–R9）只有一份实现（Dart），Swift 侧零业务逻辑——这正是 SC-003"统计与记录 100% 一致"的架构保证；快照而非直连数据库，让原生面保持纯展示。
- **备选**: 自写 App Intent + Swift 侧写库（业务逻辑两份实现，口径漂移风险）；小组件只读、点击跳 App（违反 FR-016）→ 均弃。
- **风险与对策**: 后台 isolate 打开 drift 数据库需与主 isolate 并发——SQLite WAL + 同一 App Group 路径承接；若个别 iOS 版本后台回调被系统限流，降级路径 = 按钮深链打开 App 对应目标页（widget-intent.md 已约定）。Codemagic 首次构建时验证 home_widget 交互能力为**实现期第一验证项**。

## D14. 导航与深链

- **决策**: `go_router` 声明式路由 + `target://` 自定义 scheme（`target://today`、`target://review`、`target://goal/{id}`）
- **理由**: 小组件/通知的落点统一为深链，go_router 的 URL 匹配让路由表即文档；单 NavigationStack 式极简导航（ui-contract）用 push/sheet 表达即可，无需复杂嵌套。
- **备选**: Navigator 1.0 手推（深链解析手写、易碎）→ 弃。

## D15. 无 Mac 的开发与发布循环

- **决策**: 双面循环（2026-08-18 用户确认：自有 iPhone，本地只验 Web）。**本地迭代（WSL）**：`flutter run -d chrome` 为唯一日常验证面，且 Web 端做到**全功能**——真实持久化（drift WasmDatabase → IndexedDB，刷新/重开不丢数据）、备份导出走浏览器下载/导入走文件选择、提醒页内模拟（到点弹横幅）、小组件等 iOS 专属能力占位说明；平台能力接口在 Web 提供真实或模拟实现，而非全盘假数据。**iOS 验证**：push 即触发 Codemagic 构建（含小组件扩展），通过后自动分发 TestFlight，用户在 iPhone 实机安装验收——任何时点最新代码均可装机且构建为绿（CI 门禁）。Android 循环非必需，仅保持可构建
- **理由**: 用户不维护 Android 环境，Web 是唯一零成本的本地全功能面；iPhone 实机承担 iOS 专属行为的最终验收；「push 即构建」把"打包不出错"变成每轮提交的自动门禁而非里程碑事件
- **备选**: Android 设备/模拟器作本地主面（用户明确不采用）；Web 仅 UI 演示级假数据（数据闭环问题会堆积到 iPhone 装机才暴露）；手动/tag 触发构建（绿构建保证滞后）→ 均弃。

---

## 决策与规格条款对照

| 决策 | 支撑条款 |
| ---- | ---- |
| D1/D2/D15 | Assumptions 开发环境约束（WSL/无 Mac/Codemagic/跨平台）+ CI 门禁（push 即构建 + 自动 TestFlight）+ Web 全功能本地验证 |
| D3/D4/D14 | 工程可实施性（存储/状态/路由）→ 全部 FR 的实现基础 |
| D13 | FR-016（小组件直接打卡）、SC-007 |
| D6 | Edge Cases（跨天归属）、FR-008（周一结算） |
| D7 | FR-002（下一周期生效）、FR-018（忙碌当周生效）、SC-003 |
| D8 | FR-015（导出/导入、冲突提示） |
| D9 | FR-017（生活电量） |
| D10 | FR-005（连击）、FR-004 补签联动 |
| D11 | FR-008（周结算）、Clarifications 补签透明 |

**遗留 NEEDS CLARIFICATION**: 无。

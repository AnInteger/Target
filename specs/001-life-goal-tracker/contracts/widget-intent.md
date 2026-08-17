# Contract: 小组件与打卡交互（home_widget 桥接）

**位置**: 原生孤岛 `ios/TargetWidgets/`（Swift，仅渲染）+ `lib/core/platform/widgets/`（Dart，数据与打卡逻辑） | **依据**: FR-016、SC-007、research D13

## 小组件规格（WidgetKit）

| Family | 内容 | 交互 |
| ------ | ---- | ---- |
| systemSmall（桌面） | 生活电量环（百分比）+ 今日总进度 | 点击整体 → 打开 App 今日页（`target://today`） |
| systemMedium（桌面） | 生活电量 + 今日各目标行（名称、x/y、打卡按钮） | 每行打卡按钮在小组件内直接打卡（下方交互契约） |
| accessoryCircular（锁屏） | 电量环（简化） | 点击 → 打开 App |
| accessoryRectangular（锁屏） | 今日首条未达标目标 + x/y | 点击 → 打开 App 对应目标（`target://goal/{id}`） |

## 数据路径：快照（Snapshot）

小组件不直连数据库。数据每次变更后（打卡/撤销/建改目标/忙碌模式/跨天），Dart 侧将**今日快照**经 `HomeWidget.saveWidgetData` 写入 App Group 共享存储，随后触发 timeline 刷新：

```text
snapshot keys（App Group 共享存储）:
  battery       → Int?            // 生活电量百分比；nil/缺失 = 空态"—"
  updatedAt     → ISO 8601 时刻   // 快照生成时间
  goals         → [ { id, name, colorKey, iconKey,
                      targetCount, doneCount, met, busyMode } ]   // 活跃 habit 行，排序与今日视图一致
                                    // T044 里程碑扩展（可选键，Swift 侧全部可选解码，兼容旧快照）:
                                    //   kind: "milestone", stepsDone: Int, stepsTotal: Int, deadline: "yyyy-MM-dd"
                                    // 里程碑行不含 targetCount/doneCount/met/busyMode；
                                    // medium 家族渲染为只读进度行（步骤 x/y + 倒计时），无打卡按钮
  weekProgress  → { weekStart, metGoals, totalGoals }             // 今日总进度用（只统计 habit）

Swift 侧（TargetWidgets 扩展）只做两件事：读快照 → 渲染 families；把按钮点击转发给 home_widget 的交互回调。
```

## 交互路径：打卡回调（iOS 17 交互式小组件）

```text
medium 行内打卡按钮（iOS 17+）:
  点击 → HomeWidgetBackgroundIntent → 后台启动 App 进程，在后台 isolate 中执行 Dart 回调:
    1. 前置校验（任一失败 → 快照原样重写，按钮状态不变，无副作用）:
       - goal 存在、kind == habit、status == active
       - 当日 valid 次数 < 当日目标次数（已达标的按钮在渲染侧即呈现完成态）
    2. 写入 CheckIn(day: 今天, isBackfill: false)   // 与主 App 同一仓库层、同一统计引擎
    3. 重算统计 → 重写快照（doneCount+1、电量更新）→ 刷新 timeline
  可感知结果: 小组件行内 x/y 即时 +1；无弹窗、无需打开应用主体（SC-007）
```

- **口径单源**：打卡逻辑与 R1–R9 统计只有 Dart 一份实现；Swift 侧零业务逻辑（SC-003 的架构保证）
- **降级路径**：后台回调被系统限制/数据未就绪时，按钮退化为深链打开 App 对应目标页（`target://goal/{id}`，research D13）
- **实现期第一验证项**：home_widget 交互能力在 Codemagic 首次 iOS 构建时即验证（无本地 Mac，见 research D15）

## Timeline 策略

- 刷新点：每日本地 0 点（自然日翻转）+ 每次数据变更后（Dart 侧主动）+ 忙碌模式/暂停/恢复变更后
- timeline entry 提前生成次日 0 点的切换条目，避免跨天后显示过期状态
- 快照含 `updatedAt`，Swift 侧若读到过期数据（如后台回调受限）按空态/缓存渲染，不崩溃

## 验收对应

- SC-007：从小组件看到今日状态并完成一次打卡 ≤ 5 秒、无需打开应用主体（medium family 按钮路径）

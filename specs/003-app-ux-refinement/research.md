# Research: 003 App 体验精修

Phase 0 决策记录。输入 = spec（含 2026-08-22 两条澄清：三类型均打卡；短期手动标记达成）+ 现有代码实测（router.dart / frequency_pattern.dart / tables.dart 通读）。

## D1 目标图标库：策展 Material 圆角变体，零新依赖

- **Decision**: 图标库 = Flutter 内置 Material Icons 的 rounded 变体（`Icons.*_rounded`，源出 Material Symbols，Apache 2.0）策展 ≥9 类约 40 枚，建 `GoalIconCatalog`（领域 → IconData 列表）常量表；HTML 原型用同源 Material Symbols Rounded web 字体保持像素级一致。
- **Rationale**: 用户允许「网上搜图标」，但产品已整体使用 Material 图标语言（导航条即 `Icons.home_rounded` 系）——同族策展风格天然统一、免渲染管线改动（无需 flutter_svg/SVG 资产管线）、许可 Apache 2.0 无风险、原型与实现同字形。领域覆盖实测充足：运动（directions_bike_rounded/pool_rounded/hiking_rounded）、学习（menu_book_rounded/school_rounded/translate_rounded）、健康（favorite_rounded/monitor_heart_rounded/bedtime_rounded）、创作（brush_rounded/edit_rounded/camera_rounded）、旅行（flight_rounded/luggage_rounded/map_rounded）、理财（savings_rounded/trending_up_rounded）、生活（home_rounded/cleaning_services_rounded/restaurant_rounded）、冥想（self_improvement_rounded/spa_rounded）、社交（groups_rounded/volunteer_activism_rounded）、宠物（pets_rounded）。
- **Alternatives considered**: Phosphor（MIT、六字重、风格更圆萌——需引 flutter_svg + SVG 资产管线，原型/实现两套渲染）；Tabler/Lucide（线性风格与柔彩仪表盘气质不合）；自绘一套（工作量与维护成本不成比例，且用户明示可搜）。

## D2 「达标/适用日」概念退役，统计收敛为记录语言

- **Decision**: 新模型下 stats_engine 停止计算「适用日/达标判定」（FrequencyPattern 的 isApplicableOn/达标 N 次口径退出上屏），收敛为：打卡记录数、连续记录（streak）、周节奏（周内留痕天数/目标）。今日页圆环语义统一为「今天记录了吗」（0→1，一次封顶）；习惯的「三天一次」等节奏只影响提醒排程，不构成达标判定。回顾屏维持 R3 纯回看语言（本来就是记录口径，基本不动）。
- **Rationale**: 用户删除频率问答后，per-day N 次的达标判定失去数据来源；002 周回顾 R3 定稿已把产品语言转向纯记录回看——顺势收敛，避免两套语义并存。今日环 0/1 语义让「打卡即亮」在三种类型下行为一致（澄清 Q1：三类型均打卡）。
- **Alternatives considered**: 内部保留 FrequencyPattern 派生节律（habit+一天一次→DailyFrequency(1)、三天一次→新造 Every3Days 模式）——为不上面板的概念维护一套隐藏模型，违背「设置项不得为自然语言暗逻辑」的反馈初衷，否。
- **回归策略**: 既有依赖达标断言的测试随口径改写（今日环 0/1、回顾节奏条）；V1–V8 中打卡/撤销/补签/备份路径不受影响。

## D3 频率 → 三类型迁移映射（schema v3）

- **Decision**: 一次性迁移（drift onUpgrade v2→v3，SQL 重映射 + 新列）：
  - `kind = oneshot`（一次性）或 `deadline IS NOT NULL` → **shortTerm**（保留 deadline；无 deadline 的 oneshot 补不出日期则归 longTerm）
  - 存在 daily/weekdays 频率版本 → **habit**，提醒 cadence = `daily`，时间沿用该目标现存 Reminder.time（无则 09:00 默认、开关关）
  - 存在 weekly 频率版本 → **habit**，cadence = `weekly`
  - 其余（无频率/已暂停/历史缺失）→ **longTerm**
  - `FrequencyVersions` 表停写但整表保全（退役字段不上屏）；`colorKey` 置 NULL 退役；`motivation/successCriterion` 保留列不动、退出所有表单与界面；`cueScene` 保留并继续作为提醒文案语境（是否上编辑器分组由原型轮定，spec Assumptions 已注）。
- **Rationale**: 零丢失要求退役字段只藏不删；映射规则可逆、可测试（对账用例按四分支各造一条存量）。
- **Alternatives considered**: 惰性迁移（读取时映射）——迁移语义散落仓库层，回归对账难做一次性验证，否。

## D4 短期目标完成判定：手动达成 + 续期（用户裁定 B）

- **Decision**: goals 加 `achievedAt`（NULL=未达成）与续期语义（改 deadline 即续期）；截止日到点仅排一条提醒通知（「到日子了，怎么样？」）+ 通知列表出现一条询问项；目标保持可打卡直到用户处理。详情页给「标记达成 / 续期」双入口。
- **Rationale**: 澄清 Q2 用户选 B——生活目标不由机器判死。
- **Alternatives considered**: 截止自动归档（A）、到期未标记转长期（C）均被用户否。

## D5 编辑器/详情保底导航：移入 today 分支

- **Decision**: `/goal-editor` 与 `/goal/:id` 从 GoRouter 根路由移入 StatefulShellRoute 的 today 分支作子路由——底部胶囊导航全程可见可点（FR-010）。回顾空态 CTA 与我的页入口 `context.go('/goal-editor')` 会落在 today 分支（创建后自然回到今日），语义正确。
- **Rationale**: 根因明确：现两路由挂在 shell 之外（router.dart L52-62），页面全屏覆盖导航——移进分支即恢复同图层感，无需自造导航容器。
- **Alternatives considered**: 编辑器做 bottom sheet/半屏（用户「分组折叠」诉求在整页更从容，半屏表单层级更乱）；自建 PersistentTab 容器（重复造 StatefulShellRoute 已有能力）。

## D6 通知列表：纯推导、无新表

- **Decision**: 列表页实时由现有数据推导合成，不建通知表：① 今日/明日提醒时刻表（来自 Reminders 排程 + cadence）；② 近 7 天成就时刻与全完成日（celebration/stats 既有数据）；③ streak 里程碑（当前连续记录数与最近变化）；④ 短期目标到期询问项（deadline ≤ 今天且未 achieved）。按时间倒序混排、按天分组，无已读态、无持久化。
- **Rationale**: 单机离线应用，本地通知触发时 App 多不在前台——落库的事件日志天然残缺，「推导式」才能保证列表永远完整且零迁移成本；已读态是通知系统的复杂度大头，MVP 不背。
- **Alternatives considered**: notification_events 表 + 前台回调落库（iOS 后台触发无法落库，列表将长期空洞）；接推送服务（无后端，超范围）。

## D7 账号资料：Settings 单例行加两列

- **Decision**: `SettingsRows` 加 `nickname TEXT NULL`、`avatarKey TEXT NULL`；头像 = 8 枚预设（图标库取 + 令牌环底色，不接相册选图）；默认昵称「我」。今日页左上账号区与我的页账号卡同源渲染。
- **Rationale**: 单用户单例数据并入既有 Settings 行，零新表；为将来接账号预留的是 UI 结构（头像+昵称位）而非存储抽象，不过度设计。
- **Alternatives considered**: 独立 profile 表（单行表多余）；相册头像（引入图片权限/文件管理，超出本特性价值）。

## D8 「一句话描述」= name 语义升级，无新列

- **Decision**: 不新增描述字段——现有 `goals.name` 即一句话描述，改的是表单引导（placeholder 示范完整短句：「月底前能连续跑 3 公里」式）与各屏呈现文案；长度上限放宽到 ~40 字（现 20 字短名口径）。
- **Rationale**: 用户要的是「只需要一句话」而非「多一个字段」；加列反而复活两套名称语义。
- **Alternatives considered**: name + description 双字段（双语义必然厚此薄彼，否）。

## D9 备份 v3：前向宽容、后向可读

- **Decision**: 备份 JSON 升 schemaVersion 3：goals 增 `goalType`（longTerm/shortTerm/habit）、`achievedAt`；reminders 增 `cadence`；settings 增 `nickname/avatarKey`。导入器宽容策略沿用 001 惯例：未知字段忽略、缺失字段取默认——旧版本 App 读 v3 文件可读全部基础字段（goalType 缺省按 D3 规则重推导），新版本读 v2 文件走同一条迁移映射。
- **Rationale**: 跨版本互导是 spec 边界用例；宽容解析让 v2/v3 双向不炸。
- **Alternatives considered**: 硬校验版本号拒绝导入（违背零丢失精神）。

## 汇总

无 NEEDS CLARIFICATION 残留（图标选型 D1、类型语义 D2/D3/D4、导航 D5、通知 D6、资料 D7、描述 D8、备份 D9 全部闭合）。进入 Phase 1 设计。

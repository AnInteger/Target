# Research: UI/UX 全面重设计（原型先行）

Phase 0 输出。逐项裁决 Technical Context 中的未知项与关键依赖选型；每项含决策、理由、被否的替代方案。

---

## R1 原型交付媒介与评审方式

**Decision**: 高保真原型为自包含 HTML（无外部依赖、手机逻辑视口 393×852），存放于仓库 `design/prototypes/`，本地 `python3 -m http.server` 或直接 `file://` 打开评审；`index.html` 作为评审入口（方向对比 + 屏索引 + 各屏通过状态）。用 frontend-design 技能产出。

**Rationale**: 用户环境（WSL2、无 Mac）下浏览器是唯一即时可视面；自包含 HTML 不依赖网络与构建链，评审零门槛；入库可追溯（FR-009 风格决策要有记录）。

**Alternatives considered**: Figma/Figma File API（需账号与网络协作，AI 无法直接产出 .fig，仅能出 SVG 拼装——链路长）；Flutter debug 构建（改一次要热重载，迭代慢于改 HTML；且未见先于实现）；静态图片拼图（无交互、动效无法表达）。

## R2 设计令牌的单一来源与两侧同步

**Decision**: 两阶段双源、单向翻译。原型期：令牌以 `design/tokens.css`（CSS custom properties）为源，全部 HTML 原型只引用它；风格定稿后：机械翻译为 `lib/app/design_tokens.dart`（Dart 常量，浅/深成对），`tokens.css` 降级为镜像与后续原型的基础。Swift 侧（小组件）以 `ios/TargetWidgets/DesignTokens.swift` 手工镜像色板，文件头注明"同步自 design_tokens.dart，改动需双侧同步"。

**Rationale**: 原型期需要 CSS 侧快速迭代；定稿后唯一真源必须落在交付代码（Dart），SC-004（100% 取值于令牌）才可机械校验；Swift 镜像量小（色板 + 少量尺寸），手工可承受。

**Alternatives considered**: Style Dictionary 自动三端同步（Dart/CSS/Swift codegen——一次性单用户项目引入构建链过重，令牌变更频率低）；以 CSS 为永久真源 + 运行时加载（Flutter 资产解析引入运行时耦合，且离线首帧依赖）。

## R3 深色模式实现

**Decision**: 令牌全部浅/深成对定义；`ThemeData` 仍走 Material 3 `ColorScheme`，但 seed 改为由令牌语义色组装的完整 scheme（不再 fromSeed 撒色），文字对比度按 WCAG AA 校验（正文 ≥4.5:1，大字 ≥3:1），校验在原型期用页面内对比度自查（工具或脚本），实现期抽查。

**Rationale**: 既有代码已有 light/dark 双色映射与 fromSeed 主题，成对令牌是自然扩展；fromSeed 的派生色不可控，全面重设计需要每个语义色都被设计过。

**Alternatives considered**: 保持 fromSeed 只换 seed（省事但视觉上限低，与"全面重设计"矛盾）。

## R4 动效体系

**Decision**: 只用 Flutter 内建动画（implicit `Animated*`、`AnimatedSwitcher`、少量 `CustomPainter`/`TweenAnimationBuilder`、路由 transition），打卡反馈动效 ≤600ms、成就时刻 ≤1200ms；不引入 `flutter_animate` 等编排库。

**Rationale**: 需求为轻量仪式感反馈（FR-004），内建体系足够；少一个依赖少一分 CI 风险（pub 镜像源）；性能目标 60fps 在简单属性动画下无压力。

**Alternatives considered**: `flutter_animate`（链式编排优雅，但当前动效规模小，新依赖不划算；若后续动效复杂化再评估）；Lottie/Rive（需设计工具链与运行时，体积+维护成本，否决）。

## R5 目标定义模型扩展的数据迁移

**Decision**: Drift `schemaVersion` 递增，`MigrationStrategy` 中对 Goal 表 `ALTER TABLE ADD COLUMN`，**新增列全部可空**（候选集见 data-model.md：motivation / success_criterion / cue_scene 等，最终字段以原型评审为准，但迁移 envelope 保持"可空增量"）；既有行不动，旧行新维度为空时 UI 呈现"渐进补全"引导（spec 边界场景）。备份导入导出格式随之携带新字段（向后兼容：缺字段视为空）。

**Rationale**: 可空增量迁移是零丢失的最稳路径（FR-005）；备份格式 JSON 加可选键即可向后兼容。

**Alternatives considered**: 新表 + 外键关联（查询 join 成本与迁移复杂度都高于加列，无收益）；重写表结构重建库（违反零丢失约束）。

## R6 图标与启动屏资产生成链

**Decision**: 新增 dev 依赖 `flutter_launcher_icons` + `flutter_native_splash`。品牌母版（1024×1024 PNG，含浅深两版）在原型/品牌阶段于 `design/brand/` 产出，配置写入 `pubspec.yaml`（flutter_launcher_icons/flutter_native_splash 段），本地 `dart run` 生成 iOS 全档资产；CI 打包自然携带。

**Rationale**: 两包均为纯 Dart 工具，Linux/WSL2 可跑，无 Mac 依赖；产物直写 `ios/Runner/Assets.xccontents`，Codemagic 零改动。

**Alternatives considered**: 手工各分辨率切图（易漏档、不可复现）；只在 CI 生成（本地无法预览验证，迭代慢）。

## R7 字体策略

**Decision**: 不打包任何中文 webfont。iOS 用系统栈（SF Pro + PingFang SC），Web 原型用 `system-ui` 栈近似；设计感通过字重对比、字号阶、字距、数字等宽（tabular figures，`fontFeatures: [FontFeature.tabularFigures()]`）与留白实现。若风格定稿后确需特色西文/数字字体，仅打包拉丁子集（<200KB）。

**Rationale**: 中文字体 5–15MB，直接击穿 App 体积约束；iOS 系统中文渲染质量高；"极简+设计感"的主流实现恰是系统字体+强字阶排版。

**Alternatives considered**: 打包思源黑体/霞鹜文楷等（体积否决）；云字体（离线约束否决）。

## R8 设计一致性回归手段（替代 golden test）

**Decision**: 写"令牌契约测试"（`test/design/token_contract_test.dart`）：扫描 `lib/features/` 与 `lib/app/` 源码，断言除 `design_tokens.dart` 外无 `Color(0x` 字面量、无裸 `TextStyle(` 带 color/fontSize 硬编码（白名单机制供例外并注明原因）；视觉走查仍靠 Web release 面 + 真机（复用 001 的流程与无头走查技巧）。

**Rationale**: Linux golden 基线中文为豆腐块（Ahem 兜底字体），要先加载真实字体资产才有意义，维护成本高；SC-004 的本质是"唯一来源"约束，用源码扫描机械化最直接。

**Alternatives considered**: flutter golden tests（上述字体问题 + 基线随环境漂移）；纯人工 review（不可持续，无法进 CI）。

## R9 分屏推进与并存控制

**Decision**: 推进顺序 = 今日/打卡（US2）→ 目标列表 → 编辑器+定义模型（US3）→ 周回顾/忙碌/补签（US4）→ 设置/备份/深色收尾 → 品牌素材（图标/启动屏/小组件同步）。每屏"原型评审通过 → Flutter 落地 → 回归通过 → 下一屏"，主分支小步提交（延续 001 的提交风格），不建长期并行 UI 分支。

**Rationale**: SC-006 要求并存屏 ≤1，顺序落地天然满足；今日屏最早交付且能最快验证风格方向的真实手感。

**Alternatives considered**: 先全量原型全部屏再统一切换（评审周期太长，风险后置）；特性分支长跑（合并冲突面大，与单人文档流不合）。

---

### 汇总：Technical Context 未知项清零确认

| 未知项 | 裁决 |
|---|---|
| 原型媒介 | R1 自包含 HTML + `design/prototypes/` |
| 令牌同步机制 | R2 双阶段双源单向翻译 |
| 深色模式 | R3 成对令牌 + 完整 ColorScheme |
| 动效依赖 | R4 仅内建动画 |
| 模型迁移 | R5 可空列增量迁移 |
| 图标/启动屏链路 | R6 flutter_launcher_icons + flutter_native_splash |
| 字体 | R7 系统字体 + 排版做设计感 |
| 设计回归 | R8 令牌契约测试替代 golden |
| 并存控制 | R9 顺序分屏推进 |

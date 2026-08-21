# Contract: 设计语言（Design Language / UI 契约）

本契约约束"设计令牌"的结构与使用规则，是 SC-004（100% 取值于令牌）的可校验依据。消费者：HTML 原型（`design/tokens.css`）、Flutter App（`lib/app/design_tokens.dart`）、iOS 小组件（`ios/TargetWidgets/DesignTokens.swift`）。

## 1. 令牌命名空间与结构

### 语义色（浅/深成对，必填）

| 令牌 | 用途 | 约束 |
|---|---|---|
| `background` | 页面底色 | 与 `surface` 对比形成层次，非纯白/纯黑 |
| `surface` | 卡片/容器 | 对 `onSurface` 对比度 ≥ 4.5:1 |
| `surfaceAlt` | 次级容器/分组底 | 与 `surface` 差异可感知但非强对比 |
| `onSurface` | 主文字 | 对 `background` ≥ 4.5:1（WCAG AA） |
| `onSurfaceVariant` | 次级文字 | ≥ 3:1（大字/图标场景） |
| `accent` | 主操作/强调 | 对 `accentOn` ≥ 4.5:1；每方向仅一个 |
| `positive` | 完成/达成语义 | 不与 accent 冲突 |
| `warning` | 落后/注意语义（忙碌概念已移除） | 非警告红，克制 |
| `divider` | 分隔线 | 低存在感 |

### 目标色板（8 色保留键名）

coral / amber / sage / teal / sky / indigo / plum / stone。**键名为持久化数据**（Goal.colorKey），只可校准色值、不可增删改名（否则触发数据迁移，违反零成本原则）。每色浅/深两值，深色下互仍可区分（edge case）。

### 字阶（九档）

displayLarge → labelSmall，每档定义：字号 / 行高 / 字重 / 字距。数字场景（进度、计数、日期）一律启用 tabular figures。允许超过九档映射到富文本场景，但不得在九档之外发明字号。

### 刻度类令牌

- 间距：`4 / 8 / 12 / 16 / 20 / 24 / 32 / 48`（4 的倍数，禁用奇数与越阶值）
- 圆角：`sm 8 / md 12 / lg 16 / xl 24 / full`
- 阴影：`low / mid / high` 三档；深色模式以表面亮度差表达层级，禁用深色下重阴影
- 动效：`fast 150ms / base 250ms / slow 450ms / celebration ≤1200ms`；缓动统一用标准减速曲线族

## 2. 使用规则（MUST）

1. **唯一来源**：屏幕代码只准 import 令牌文件取值；出现 `Color(0x…)`、裸 `TextStyle(color:…, fontSize:…)` 即违约（`test/design/token_contract_test.dart` 扫描强制，白名单须注明原因）
2. **成对完整**：任一颜色令牌必须同时给出浅/深两值，缺一不得合入
3. **键名稳定**：目标色板键名与存储值冻结（见上）
4. **三端镜像同步**：Dart 为真源；CSS/Swift 镜像文件头必须注明"同步自 design_tokens.dart"；改色必须一次提交内完成双侧
5. **方向探索期豁免**：R1 阶段的 direction-*.html 允许内联试色，但定稿转正进 `tokens.css` 时必须收敛为令牌

## 3. 风格方向记录（FR-009）

`design/reviews.md` 中必须记录：参与对比的方向列表（≥2）、每方向一句定位描述、用户选定结论（或融合说明）、日期。此记录是后续全部屏幕的令牌取值依据。

## 4. 变更记录

- 2026-08-19：间距刻度增补 `20`（定稿方向 G「柔彩仪表盘」卡片内边距取参照工程实测 p-5=20px）。其余条款不变。
- 2026-08-19（今日屏 R3 评审驱动）：
  - **浅色底幕回调**：bg-grad 四档由 `#f5e6f5/#ede0f8/#ddd0f0/#ccc0e8`（薰衣草饱和偏高、与白卡对比发闷）回调为更接近定稿参照的透气粉紫 `#f9edf4/#f5e8f6/#f0e2f8/#e9dbf2`；`background` 均值同步 `#e9dcf0 → #f1e5f4`。深色不变。
  - **中文字重二档化**：中文回退字体（PingFang/YaHei/Noto）对 500/600 无独立真实字重，浏览器伪加粗导致粗细观感不统一——字阶中 `titleLarge/titleMedium 600→700`、`labelSmall（及 Dart 侧 labelMedium/labelLarge）500→400`。中文正文用 400、强调统一 700、数字 tnum 700、display 800 不变；纯拉丁数字场景允许 Inter 真实中间字重（如状态栏 600）。
- 2026-08-20（今日屏 R3 自审驱动）：
  - **头像装饰渐变对**：新增语义令牌 `--grad-avatar-a/b`（浅深同值 `#eab54e → #ef8a80`），Dart 侧 `kAvatarGradA/B`。原则：目标色板是**文字级**校准（浅色 -500/-600 重量保 AA），装饰性填充（头像等身份元素）不得复用文字值——须取填充级明度。此对取值恰与深色目标色 amber/coral 相同（同属填充级明度，巧合而非引用）。
- 2026-08-20（今日屏 R4 评审驱动）——浅色主题整体调校（深色不动）：
  - **底幕渐变可见化（R4 追加，覆盖同日早前"调淡"决策）**：参照图屏幕内像素采样锚点直接采用——bg-grad 四档 `#ecd8e0/#e2d3e9/#d9d1f2/#d1ccf8`（顶部玫瑰粉 → 底部 periwinkle，135deg，均值 #ded3ed）。原则：底幕渐变必须可感（首末档 R-B 摆幅 ≥35），不允许收敛成近白纯色；同时正文/次级文字对渐变全段分别保持 ≥10:1 / ≥4.5:1（`--on-surface-variant` 相应加深为 `#565264`）。
  - **强调色墨梅化**：`--accent #17181c（纯黑）→ #252230（墨梅）`；随族微调 `--on-surface #1d1a24`、`--divider #e8e3f0`、`--surface-alt #f5f0f9`。原则：主操作强调不取纯黑（#000 系），一律带品牌紫相的墨色，深浅两主题各自保持"反色实心"语义。
  - **shadow-low 弥散化**：浅色 `0 1px 3px → 0 2px 10px`（同为 6% 不透明度）——白卡分层由"贴边硬影"改"弥散软影"，与参照卡片的轻阴影一致。

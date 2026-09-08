# 006 契约 · 设计语言 v3（iOS 原生 + 局部 Liquid Glass）

- 真源：原型期 = `design/tokens.css`（?v=v3a）；实现期 = `lib/app/design_tokens.dart`
  为真源，CSS 与 `ios/TargetWidgets/DesignTokens.swift` 为镜像。
- **改值一次提交内三端同步**（沿用 002 契约 §2-4），token_contract_test 对账。

## 1. 语义色（浅 / 深成对，成键缺一即契约失败）

| 键 | 浅 | 深 | 用途 |
|---|---|---|---|
| background | #f2f2f7 | #000000 | 分组底 |
| surface | #ffffff | #1c1c1e | 卡片 |
| surfaceAlt | #f2f2f7 | #2c2c2e | 卡上内嵌控件底 |
| onSurface | #1c1c1e | #f5f5f7 | 主文 |
| onSurfaceVariant | #6c6c70 | #a5a5ab | 次文（≥4.5:1 on surface） |
| onSurfaceTertiary | #8e8e93 | #7c7c83 | 时间戳/占位（非正文级） |
| accent | #007aff | #0a84ff | 行动色/图形/选中 |
| accentOn | #ffffff | #ffffff | 实底按钮标签（17px/600 大字号档） |
| accentTint | 10% 蓝 | 22% 蓝 | tab 胶囊选中底/tile 底 |
| accentText | #0066d6 | #409cff | 链接/正文级蓝（≥4.5:1） |
| milestone | #ff9500 | #ff9f0a | 旗帜/达成节点（图形级） |
| milestoneTint | #fff3e0 | #3a2a10 | 暖色 tile |
| milestoneText | #9a5700 | #ffb86b | 正文级橙 |
| positive / positiveFill / positiveOn | iOS 绿族 | 同左提亮 | 开关/完成 |
| warning | #9a5700 | #ffb86b | 落后语义 |
| divider | #e5e5ea | #38383a | 发丝线 |
| scrim | 32% 黑 | 55% 黑 | sheet/菜单遮罩 |
| danger / dangerOn | iOS 红族 | 同左 | 删除 |
| badge / badgeOn | iOS 红 | 同左 | 角标（预留） |

## 2. 头部渐变与玻璃

- 头部渐变（tab 屏专属，非全屏底幕）：浅 `180deg #e2d5f0 0% → #edd8e8 18% → #f2f2f7 42%`；
  深 `#362f4a → #2b2539 16% → #161618 40% → #000`。
- Liquid Glass 三档（仅限：底栏胶囊、悬浮记录钮、头部圆形控件、上下文菜单、小组件）：
  - shell：rgba(242,242,247,.72) / rgba(28,28,30,.72) · blur 24 · saturate 180%/160%
  - card：rgba(255,255,255,.62) / rgba(44,44,46,.62) · blur 12
  - border/highlight：0.5px 白 65%/白 12% + inset 0.5px 白 85%/白 18%
- 玻璃不用于正文卡（白卡保持实底，保证对比度可计算）。

## 3. 字阶（SF 阶梯）

display 34/32/26 · title 22/17/15 · body 17/15/13 · label 11（数字一律 tabular）。
display 档负字距 -0.02em。

## 4. 度量

- 页缘 20（--screen-pad-x）、卡缘 16；圆角 sm10/md12/lg16/xl24/full；
- 阴影：low=卡(0 1 6 · 7%)、mid=悬浮(0 2 16 · 10%)、high=sheet(0 -6 40 · 18%)、
  cta=主行动钮蓝色光晕；
- 动效：fast150/base250/slow450/sheet320ms，标准减速曲线；celebration 档随成就动效退役删除。

## 5. 分类色板（iOS 系统色，浅深成对）

blue/green/orange/purple/pink/indigo/teal/red（--palette-*，深色用系统暗色变体）。
目标色 = 分类默认色，可改；图标色随目标色。

## 6. 禁则

- 正文级文本不得使用 accent（用 accentText）/ milestone（用 milestoneText）直书。
- onSurfaceTertiary 不得用于承载必要信息的正文。
- 玻璃表面上的文本仅限 onSurface 级；玻璃底对比度按合成底计算（走查口径同 005）。
- 旧「健康/习惯/目标」三大类着色不回潮；--major-*/--grad-* 键仅为 v2 留档可解析。

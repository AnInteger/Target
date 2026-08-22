//
//  DesignTokens.swift
//  TargetWidgets
//
//  设计令牌镜像（T029）——同步自 `lib/app/design_tokens.dart`（三端唯一
//  真源），原型侧另见 `design/tokens.css`；改色必须一次提交内双侧同步。
//  小组件不引 Blur/底幕渐变（系统 containerBackground 已表达材质），
//  这里只镜像组件实际取用的色值与圆角刻度。
//

import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// 语义色浅/深成对（镜像 TargetPalette.light / .dark 的组件子集）。
struct WidgetPalette {
    let surface: Color
    let surfaceAlt: Color
    let onSurface: Color
    let onSurfaceVariant: Color
    let accent: Color
    let positive: Color
    let positiveFill: Color
    let warning: Color
    let divider: Color

    /// 浅色 · v2（同步自 tokens.css :root；#F5F5F7 灰底 + 白卡 + 蓝强调）。
    static let light = WidgetPalette(
        surface: Color(hex: 0xFFFFFF),
        surfaceAlt: Color(hex: 0xF2F2F7),
        onSurface: Color(hex: 0x1C1C1E),
        onSurfaceVariant: Color(hex: 0x6E6E73),
        accent: Color(hex: 0x2196F3),
        positive: Color(hex: 0x188038),
        positiveFill: Color(hex: 0x34C759),
        warning: Color(hex: 0xB26100),
        divider: Color(hex: 0xE5E5EA))

    /// 深色 · v2（同步自 tokens.css dark 块；#121212 底 + 深灰卡 + 亮蓝强调）。
    static let dark = WidgetPalette(
        surface: Color(hex: 0x1E1E1E),
        surfaceAlt: Color(hex: 0x252525),
        onSurface: Color(hex: 0xFFFFFF),
        onSurfaceVariant: Color(hex: 0xB3B3B3),
        accent: Color(hex: 0x00B0FF),
        positive: Color(hex: 0x4ADE80),
        positiveFill: Color(hex: 0x4ADE80),
        warning: Color(hex: 0xFFB86B),
        divider: Color(hex: 0x333333))
}

enum DesignTokens {
    /// 三大类常驻色（004：GoalColor 8 色退役——colorKey 003 起恒空，
    /// 小组件目标行暂统一主强调蓝，键位 = MajorCategory.name）。
    static let majorHealthLight = Color(hex: 0x34A853)
    static let majorHabitLight = Color(hex: 0xFF9800)
    static let majorGoalLight = Color(hex: 0x2196F3)
    static let majorHealthDark = Color(hex: 0x4ADE80)
    static let majorHabitDark = Color(hex: 0xFFA726)
    static let majorGoalDark = Color(hex: 0x00B0FF)

    static func majorColor(_ key: String, dark: Bool) -> Color {
        switch key {
        case "health": return dark ? majorHealthDark : majorHealthLight
        case "habit": return dark ? majorHabitDark : majorHabitLight
        default: return dark ? majorGoalDark : majorGoalLight
        }
    }

    static func palette(_ dark: Bool) -> WidgetPalette {
        dark ? .dark : .light
    }

    /// 头像装饰渐变对（浅深同值；kAvatarGradA/B，身份填充非文字场景；
    /// 004 v2 = 品牌绿→蓝）。
    static let avatarGradA = Color(hex: 0x34C759)
    static let avatarGradB = Color(hex: 0x2196F3)

    /// 圆角刻度（AppRadius.md/lg 的组件侧镜像）。
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 16
}

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

    /// 浅色 ·「柔彩仪表盘」（同步自 tokens.css :root；accent 墨梅 #252230）。
    static let light = WidgetPalette(
        surface: Color(hex: 0xFFFFFF),
        surfaceAlt: Color(hex: 0xF5F0F9),
        onSurface: Color(hex: 0x1D1A24),
        onSurfaceVariant: Color(hex: 0x565264),
        accent: Color(hex: 0x252230),
        positive: Color(hex: 0x5C7D10),
        positiveFill: Color(hex: 0xB5E550),
        warning: Color(hex: 0x9A6700),
        divider: Color(hex: 0xE8E3F0))

    /// 深色 · 暗紫底幕 + 反色强调（同步自 tokens.css dark 块）。
    static let dark = WidgetPalette(
        surface: Color(hex: 0x241E33),
        surfaceAlt: Color(hex: 0x2D2640),
        onSurface: Color(hex: 0xF2EFF7),
        onSurfaceVariant: Color(hex: 0xA8A1B8),
        accent: Color(hex: 0xF2EFF7),
        positive: Color(hex: 0xB5E550),
        positiveFill: Color(hex: 0xB5E550),
        warning: Color(hex: 0xE8B04B),
        divider: Color(hex: 0x322B44))
}

enum DesignTokens {
    /// 目标色（**键名冻结** = Goal.colorKey 持久化数据；浅 ≈ -500/-600
    /// 重量，深提亮两档保持 8 色互可区分——与 GoalColor 枚举逐值对齐）。
    static let goalLight: [String: Color] = [
        "coral": Color(hex: 0xD9534F),
        "amber": Color(hex: 0xC98A1B),
        "sage": Color(hex: 0x4E9D68),
        "teal": Color(hex: 0x2B8F84),
        "sky": Color(hex: 0x4483C4),
        "indigo": Color(hex: 0x5B6AB0),
        "plum": Color(hex: 0x9A5FA0),
        "stone": Color(hex: 0x7A7E87),
    ]

    static let goalDark: [String: Color] = [
        "coral": Color(hex: 0xEF8A80),
        "amber": Color(hex: 0xEAB54E),
        "sage": Color(hex: 0x7CC796),
        "teal": Color(hex: 0x6FC4B9),
        "sky": Color(hex: 0x85B8E8),
        "indigo": Color(hex: 0x9AA5E0),
        "plum": Color(hex: 0xCF9DD2),
        "stone": Color(hex: 0xADAFB6),
    ]

    static func goalColor(_ key: String, dark: Bool) -> Color {
        let table = dark ? goalDark : goalLight
        return table[key] ?? table["teal"]!
    }

    static func palette(_ dark: Bool) -> WidgetPalette {
        dark ? .dark : .light
    }

    /// 头像装饰渐变对（浅深同值；kAvatarGradA/B，身份填充非文字场景）。
    static let avatarGradA = Color(hex: 0xEAB54E)
    static let avatarGradB = Color(hex: 0xEF8A80)

    /// 圆角刻度（AppRadius.md/lg 的组件侧镜像）。
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 16
}

//
//  DesignTokens.swift
//  TargetWidgets
//
//  v3 设计令牌镜像（006）——同步自 `lib/app/design_tokens.dart`（三端唯一
//  真源），原型侧另见 `design/tokens.css`（?v=v3b）；改值一次提交内
//  三端同步。小组件只镜像组件实际取用的色值与圆角刻度。
//
//  v3 语义：iOS 原生色系（蓝 #007AFF/#0A84FF、里程碑橙对、玻璃浅档）。
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
    let onSurfaceTertiary: Color
    let accent: Color
    let accentText: Color
    let milestone: Color
    let milestoneTint: Color
    let milestoneText: Color
    let positive: Color
    let positiveFill: Color
    let warning: Color
    let divider: Color

    /// 浅色 · v3（iOS 分组底 #F2F2F7 + 白卡 + 系统蓝 + 里程碑橙）。
    static let light = WidgetPalette(
        surface: Color(hex: 0xFFFFFF),
        surfaceAlt: Color(hex: 0xF2F2F7),
        onSurface: Color(hex: 0x1C1C1E),
        onSurfaceVariant: Color(hex: 0x6C6C70),
        onSurfaceTertiary: Color(hex: 0x8E8E93),
        accent: Color(hex: 0x007AFF),
        accentText: Color(hex: 0x0066D6),
        milestone: Color(hex: 0xFF9500),
        milestoneTint: Color(hex: 0xFFF3E0),
        milestoneText: Color(hex: 0x9A5700),
        positive: Color(hex: 0x188038),
        positiveFill: Color(hex: 0x34C759),
        warning: Color(hex: 0x9A5700),
        divider: Color(hex: 0xE5E5EA))

    /// 深色 · v3（纯黑底 + #1C1C1E 卡 + 系统蓝暗档 + 里程碑橙暗档）。
    static let dark = WidgetPalette(
        surface: Color(hex: 0x1C1C1E),
        surfaceAlt: Color(hex: 0x2C2C2E),
        onSurface: Color(hex: 0xF5F5F7),
        onSurfaceVariant: Color(hex: 0xA5A5AB),
        onSurfaceTertiary: Color(hex: 0x7C7C83),
        accent: Color(hex: 0x0A84FF),
        accentText: Color(hex: 0x409CFF),
        milestone: Color(hex: 0xFF9F0A),
        milestoneTint: Color(hex: 0x3A2A10),
        milestoneText: Color(hex: 0xFFB86B),
        positive: Color(hex: 0x30D158),
        positiveFill: Color(hex: 0x30D158),
        warning: Color(hex: 0xFFB86B),
        divider: Color(hex: 0x38383A))
}

enum DesignTokens {
    /// v3 分类色板（iOS 系统色 9 键；goals.colorKey 值域，
    /// 镜像 GoalPalette.light/dark）。
    static let paletteLight: [String: Color] = [
        "blue": Color(hex: 0x007AFF),
        "green": Color(hex: 0x34C759),
        "orange": Color(hex: 0xFF9500),
        "purple": Color(hex: 0xAF52DE),
        "pink": Color(hex: 0xFF2D55),
        "indigo": Color(hex: 0x5856D6),
        "teal": Color(hex: 0x30B0C7),
        "red": Color(hex: 0xFF3B30),
        "gray": Color(hex: 0x8E8E93),
    ]

    static let paletteDark: [String: Color] = [
        "blue": Color(hex: 0x0A84FF),
        "green": Color(hex: 0x30D158),
        "orange": Color(hex: 0xFF9F0A),
        "purple": Color(hex: 0xBF5AF2),
        "pink": Color(hex: 0xFF375F),
        "indigo": Color(hex: 0x5E5CE6),
        "teal": Color(hex: 0x40C8E0),
        "red": Color(hex: 0xFF453A),
        "gray": Color(hex: 0x98989F),
    ]

    static func palette(_ dark: Bool) -> WidgetPalette {
        dark ? .dark : .light
    }

    /// 按 colorKey 取色（未知键回退 gray）。
    static func goalColor(_ key: String, dark: Bool) -> Color {
        let map = dark ? paletteDark : paletteLight
        return map[key] ?? map["gray"]!
    }

    /// 圆角刻度（AppRadius.sm/md/lg/xl 的组件侧镜像）。
    static let radiusSm: CGFloat = 10
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 16
    static let radiusXl: CGFloat = 24
}

//
//  TodayWidgetBundle.swift
//  TargetWidgets
//
//  WidgetKit 小组件入口（纯渲染，零业务逻辑——数据经 App Group 快照由 Dart
//  侧写入，contracts/widget-intent.md）。T029 将扩展为完整 4-family 实现；
//  本占位版本保证 Phase 1 的 CI 构建为绿。
//
//  Created by Target on 2026-08-18.
//

import SwiftUI
import WidgetKit

@main
struct TargetWidgetBundle: WidgetBundle {
  var body: some Widget {
    TodayWidget()
  }
}

struct TodayEntry: TimelineEntry {
  let date: Date
}

struct TodayProvider: TimelineProvider {
  func placeholder(in context: Context) -> TodayEntry {
    TodayEntry(date: Date())
  }

  func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
    completion(TodayEntry(date: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
    completion(Timeline(entries: [TodayEntry(date: Date())], policy: .atEnd))
  }
}

struct TodayWidgetView: View {
  var entry: TodayEntry

  var body: some View {
    Text("Target")
  }
}

struct TodayWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "TodayWidget", provider: TodayProvider()) { entry in
      TodayWidgetView(entry: entry)
    }
    .configurationDisplayName("今日")
    .description("生活电量与今日目标")
  }
}

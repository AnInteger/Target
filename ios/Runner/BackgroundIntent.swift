//
//  BackgroundIntent.swift
//  Runner
//
//  小组件内打卡按钮的后台回调入口（home_widget 交互式小组件, iOS 17+）。
//  本文件同时编译进 Runner 与 TargetWidgets 两个 target（与 home_widget
//  官方 example 布局一致）。实际打卡口径在 Dart 侧同一实现（widget-intent.md）。
//
//  Created by Target on 2026-08-18.
//

import AppIntents
import Foundation
import home_widget

@available(iOS 17, *)
public struct WidgetCheckInIntent: AppIntent {
  static public var title: LocalizedStringResource = "Target 小组件打卡"

  @Parameter(title: "Widget URI")
  var url: URL?

  @Parameter(title: "AppGroup")
  var appGroup: String?

  public init() {}

  public init(url: URL?, appGroup: String?) {
    self.url = url
    self.appGroup = appGroup
  }

  public func perform() async throws -> some IntentResult {
    await HomeWidgetBackgroundWorker.run(url: url, appGroup: appGroup!)

    return .result()
  }
}

/// 保证应用被完全挂起时小组件仍可交互（后台启动 App 进程执行 Dart 回调，
/// 不把应用带到前台——SC-007 "无需打开应用主体"）。
@available(iOS 17, *)
@available(iOSApplicationExtension, unavailable)
extension WidgetCheckInIntent: ForegroundContinuableIntent {}

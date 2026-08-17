/// 平台能力接口（tasks.md T012，plan.md Structure Decision #2）。
///
/// UI 与业务只面向这些接口；各平台实现：
/// - 通知：iOS/Android = flutter_local_notifications；Web = 页内横幅模拟（FR-007
///   权限被拒不阻塞全功能）
/// - 小组件：iOS = home_widget；Web = 占位（无桌面小组件概念，说明文案呈现）
/// - 分享/导出：share_plus / Web 浏览器下载
/// - 文件选择：file_picker（全平台）
library;

import '../models/calendar_types.dart';

/// Web 模拟通知的横幅消息（AppShell 监听并渲染）。
class NotificationBanner {
  const NotificationBanner({required this.id, required this.title, required this.body});

  final int id;
  final String title;
  final String body;
}

abstract class NotificationGateway {
  /// 请求权限；未授权返回 false，全功能仍可用、不报错（FR-007）。
  Future<bool> requestPermission();

  Future<bool> get isPermissionGranted;

  /// 每日 [time] 重复本地通知（目标提醒 / 每日概要）。
  /// 内容由调用方按"当日已达标目标裁剪"后传入（FR-006）。
  Future<void> scheduleDaily({
    required int id,
    required LocalTime time,
    required String title,
    required String body,
  });

  Future<void> cancel(int id);

  Future<void> cancelAll();

  /// Web 模拟通道：到点的"通知"以页内横幅呈现；原生实现恒为空流。
  Stream<NotificationBanner> get banners;
}

/// 小组件快照（contracts/widget-intent.md 的 Dart 侧入口）。
abstract class WidgetGateway {
  /// 写入快照数据并刷新小组件（iOS 经 App Group UserDefaults）。
  Future<void> saveSnapshot(Map<String, Object?> snapshot);

  /// 用户点击小组件跳转的 URI 流（target:// 深链）。
  Stream<Uri> get widgetClicked;
}

abstract class ShareGateway {
  Future<void> shareText(String text);

  /// 导出备份文件：原生走分享面板，Web 触发浏览器下载。
  Future<void> exportFile({
    required String fileName,
    required List<int> bytes,
    required String mime,
  });
}

class PickedFile {
  const PickedFile({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}

abstract class FilePickGateway {
  /// 选择备份文件（.targetbackup / .json）；用户取消返回 null。
  Future<PickedFile?> pickBackupFile();
}

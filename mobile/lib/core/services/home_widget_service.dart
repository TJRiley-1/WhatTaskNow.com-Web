import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  HomeWidgetService._();

  static const String _appGroupId = 'com.whatnow.app.widget';
  static const String _androidWidgetClass = 'WhatNowWidgetProvider';

  /// Initialize the home widget service and configure the app group.
  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
    await registerInteractivityCallback();
  }

  /// Update the home screen widget with the given task data.
  ///
  /// Pass [taskName] and [taskType] to show the current task. If both are
  /// null the widget will display a "no task" state.
  static Future<void> updateWidget({
    String? taskName,
    String? taskType,
  }) async {
    final hasTask = taskName != null && taskName.isNotEmpty;

    await HomeWidget.saveWidgetData<String>('task_name', taskName ?? 'No task available');
    await HomeWidget.saveWidgetData<String>('task_type', taskType ?? '');
    await HomeWidget.saveWidgetData<bool>('has_task', hasTask);

    await HomeWidget.updateWidget(
      androidName: _androidWidgetClass,
    );
  }

  /// Register an interactivity callback so the widget can launch the app.
  static Future<void> registerInteractivityCallback() async {
    await HomeWidget.registerInteractivityCallback(_interactivityCallback);
  }
}

/// Top-level callback for widget interaction events.
@pragma('vm:entry-point')
Future<void> _interactivityCallback(Uri? uri) async {
  // The widget was tapped; the app will be brought to the foreground
  // automatically. Custom deep-link handling can be added here if needed.
}

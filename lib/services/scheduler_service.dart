import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../models/scheduled_task.dart';

/// Manages scheduled automation tasks using WorkManager.
///
/// Tasks are persisted in SharedPreferences as JSON and registered with
/// WorkManager for background execution.
class SchedulerService {
  static const String _prefsKey = 'scheduled_tasks';
  static const String _taskPrefix = 'arcane_flow_task_';

  List<ScheduledTask> _tasks = [];
  List<ScheduledTask> get tasks => List.unmodifiable(_tasks);

  Future<void> init() async {
    await _loadTasks();
    // Re-register any non-completed tasks
    for (final task in _tasks) {
      if (!task.isCompleted) {
        await _registerWorkManagerTask(task);
      }
    }
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      _tasks = list
          .map((e) => ScheduledTask.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_prefsKey, jsonStr);
  }

  /// Schedule a new task.
  Future<ScheduledTask> scheduleTask({
    required String goal,
    required DateTime scheduledAt,
    bool isRepeating = false,
    String? repeatInterval,
  }) async {
    final id = '${_taskPrefix}${DateTime.now().millisecondsSinceEpoch}';
    final task = ScheduledTask(
      id: id,
      goal: goal,
      scheduledAt: scheduledAt,
      isRepeating: isRepeating,
      repeatInterval: repeatInterval,
    );
    _tasks.add(task);
    await _saveTasks();
    await _registerWorkManagerTask(task);
    return task;
  }

  /// Cancel a scheduled task.
  Future<void> cancelTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks();
    await Workmanager().cancelByTag(taskId);
  }

  /// Mark a task as completed.
  Future<void> markCompleted(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx >= 0) {
      _tasks[idx] = _tasks[idx].copyWith(isCompleted: true);
      await _saveTasks();
      await Workmanager().cancelByTag(taskId);
    }
  }

  Future<void> _registerWorkManagerTask(ScheduledTask task) async {
    final delay = task.scheduledAt.difference(DateTime.now());
    final initialDelay = delay.isNegative ? Duration.zero : delay;

    final constraints = Constraints(
      networkType: NetworkType.connected,
    );

    if (task.isRepeating) {
      final interval = switch (task.repeatInterval) {
        'daily' => Duration.days(1),
        'weekly' => Duration.days(7),
        _ => Duration.days(1),
      };
      await Workmanager().registerPeriodicTask(
        task.id,
        'executeScheduledTask',
        tag: task.id,
        initialDelay: initialDelay,
        frequency: interval,
        constraints: constraints,
        inputData: {'goal': task.goal, 'taskId': task.id},
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    } else {
      await Workmanager().registerOneOffTask(
        task.id,
        'executeScheduledTask',
        tag: task.id,
        initialDelay: initialDelay,
        constraints: constraints,
        inputData: {'goal': task.goal, 'taskId': task.id},
      );
    }
  }

  /// Get all pending (non-completed) tasks.
  List<ScheduledTask> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList();
}
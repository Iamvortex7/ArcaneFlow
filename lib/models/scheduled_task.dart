/// Represents a scheduled automation task.
class ScheduledTask {
  final String id;
  final String goal;
  final DateTime scheduledAt;
  final bool isRepeating;
  final String? repeatInterval; // 'daily', 'weekly', null
  final bool isCompleted;

  ScheduledTask({
    required this.id,
    required this.goal,
    required this.scheduledAt,
    this.isRepeating = false,
    this.repeatInterval,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'goal': goal,
        'scheduledAt': scheduledAt.toIso8601String(),
        'isRepeating': isRepeating,
        'repeatInterval': repeatInterval,
        'isCompleted': isCompleted,
      };

  factory ScheduledTask.fromJson(Map<String, dynamic> json) => ScheduledTask(
        id: json['id'] as String,
        goal: json['goal'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        isRepeating: json['isRepeating'] as bool? ?? false,
        repeatInterval: json['repeatInterval'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  ScheduledTask copyWith({
    String? id,
    String? goal,
    DateTime? scheduledAt,
    bool? isRepeating,
    String? repeatInterval,
    bool? isCompleted,
  }) =>
      ScheduledTask(
        id: id ?? this.id,
        goal: goal ?? this.goal,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        isRepeating: isRepeating ?? this.isRepeating,
        repeatInterval: repeatInterval ?? this.repeatInterval,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}
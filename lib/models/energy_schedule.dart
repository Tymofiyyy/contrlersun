// lib/models/energy_schedule.dart
class EnergySchedule {
  final int? id;
  final String deviceId;
  final int userId;
  final String name;
  final String targetMode; // 'solar' або 'grid'
  final int hour;
  final int minute;
  final String repeatType; // 'once', 'daily', 'weekly', 'weekdays', 'weekends'
  final List<int>? repeatDays; // 0-6 (неділя-субота) для weekly
  final bool isEnabled;
  final DateTime? lastExecuted;
  final DateTime? nextExecution;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EnergySchedule({
    this.id,
    required this.deviceId,
    required this.userId,
    required this.name,
    required this.targetMode,
    required this.hour,
    required this.minute,
    required this.repeatType,
    this.repeatDays,
    required this.isEnabled,
    this.lastExecuted,
    this.nextExecution,
    this.createdAt,
    this.updatedAt,
  });

  factory EnergySchedule.fromJson(Map<String, dynamic> json) {
    return EnergySchedule(
      id: json['id'],
      deviceId: json['device_id'],
      userId: json['user_id'],
      name: json['name'],
      targetMode: json['target_mode'],
      hour: json['hour'],
      minute: json['minute'],
      repeatType: json['repeat_type'],
      repeatDays: json['repeat_days'] != null
          ? List<int>.from(json['repeat_days'])
          : null,
      isEnabled: json['is_enabled'] ?? true,
      lastExecuted: json['last_executed'] != null
          ? DateTime.parse(json['last_executed'])
          : null,
      nextExecution: json['next_execution'] != null
          ? DateTime.parse(json['next_execution'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'device_id': deviceId,
      'user_id': userId,
      'name': name,
      'target_mode': targetMode,
      'hour': hour,
      'minute': minute,
      'repeat_type': repeatType,
      if (repeatDays != null) 'repeat_days': repeatDays,
      'is_enabled': isEnabled,
      if (lastExecuted != null)
        'last_executed': lastExecuted!.toIso8601String(),
      if (nextExecution != null)
        'next_execution': nextExecution!.toIso8601String(),
    };
  }

  // Для створення/оновлення через API
  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'targetMode': targetMode,
      'hour': hour,
      'minute': minute,
      'repeatType': repeatType,
      if (repeatDays != null) 'repeatDays': repeatDays,
      'isEnabled': isEnabled,
    };
  }

  String get timeString {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get repeatTypeDisplay {
    switch (repeatType) {
      case 'once':
        return 'Одноразово';
      case 'daily':
        return 'Щодня';
      case 'weekly':
        return 'Щотижня';
      case 'weekdays':
        return 'Пн-Пт';
      case 'weekends':
        return 'Сб-Нд';
      default:
        return repeatType;
    }
  }

  String get weekDaysDisplay {
    if (repeatDays == null || repeatDays!.isEmpty) return '';

    final dayNames = ['Нд', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
    return repeatDays!.map((day) => dayNames[day]).join(', ');
  }

  String get targetModeDisplay {
    return targetMode == 'solar' ? 'Сонячна' : 'Міська';
  }

  String get targetModeIcon {
    return targetMode == 'solar' ? '☀️' : '🏙️';
  }

  bool get isSolar => targetMode == 'solar';
  bool get isGrid => targetMode == 'grid';

  EnergySchedule copyWith({
    int? id,
    String? deviceId,
    int? userId,
    String? name,
    String? targetMode,
    int? hour,
    int? minute,
    String? repeatType,
    List<int>? repeatDays,
    bool? isEnabled,
    DateTime? lastExecuted,
    DateTime? nextExecution,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EnergySchedule(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetMode: targetMode ?? this.targetMode,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      nextExecution: nextExecution ?? this.nextExecution,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'EnergySchedule(id: $id, name: $name, time: $timeString, mode: $targetMode, repeat: $repeatType, enabled: $isEnabled)';
  }
}

// Enum для типів повторення
enum ScheduleRepeatType {
  once('once', 'Одноразово'),
  daily('daily', 'Щодня'),
  weekly('weekly', 'Щотижня (вибрані дні)'),
  weekdays('weekdays', 'Будні дні (Пн-Пт)'),
  weekends('weekends', 'Вихідні (Сб-Нд)');

  final String value;
  final String displayName;

  const ScheduleRepeatType(this.value, this.displayName);

  static ScheduleRepeatType fromString(String value) {
    return ScheduleRepeatType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ScheduleRepeatType.once,
    );
  }
}

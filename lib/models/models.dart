// ── Glucose Reading ──
class GlucoseReading {
  final int? id;
  final double val;
  final String whenTaken;
  final String date;
  final String time;
  final String? note;
  final int createdAt;

  GlucoseReading({
    this.id, required this.val, required this.whenTaken,
    required this.date, required this.time, this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'val': val, 'when_taken': whenTaken, 'date': date,
    'time': time, 'note': note, 'created_at': createdAt,
  };

  static GlucoseReading fromMap(Map<String, dynamic> m) => GlucoseReading(
    id: m['id'], val: m['val'], whenTaken: m['when_taken'],
    date: m['date'], time: m['time'], note: m['note'],
    createdAt: m['created_at'],
  );

  String get status {
    final isFasting = whenTaken == 'صائم';
    if (isFasting) {
      if (val < 0.70) return 'منخفض';
      if (val <= 0.99) return 'طبيعي';
      if (val <= 1.25) return 'ما قبل السكري';
      return 'مرتفع';
    } else {
      if (val < 0.70) return 'منخفض';
      if (val <= 1.39) return 'طبيعي';
      if (val <= 1.99) return 'مرتفع قليلاً';
      return 'مرتفع جداً';
    }
  }

  int get statusColor {
    switch (status) {
      case 'طبيعي': return 0xFF00c853;
      case 'منخفض': return 0xFF2196f3;
      case 'ما قبل السكري': return 0xFFff9800;
      default: return 0xFFf44336;
    }
  }
}

// ── BP Reading ──
class BPReading {
  final int? id;
  final double sys;
  final double dia;
  final int? pulse;
  final String position;
  final String date;
  final String time;
  final String? note;
  final int createdAt;

  BPReading({
    this.id, required this.sys, required this.dia, this.pulse,
    required this.position, required this.date, required this.time,
    this.note, required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'sys': sys, 'dia': dia, 'pulse': pulse, 'position': position,
    'date': date, 'time': time, 'note': note, 'created_at': createdAt,
  };

  static BPReading fromMap(Map<String, dynamic> m) => BPReading(
    id: m['id'], sys: m['sys'], dia: m['dia'], pulse: m['pulse'],
    position: m['position'] ?? 'جالس', date: m['date'], time: m['time'],
    note: m['note'], createdAt: m['created_at'],
  );

  String get status {
    if (sys > 18 || dia > 12) return 'مرتفع جداً';
    if (sys > 14 || dia > 9) return 'مرتفع';
    if (sys > 13 || dia > 8) return 'مرتفع قليلاً';
    if (sys < 9) return 'منخفض';
    return 'طبيعي';
  }

  int get statusColor {
    switch (status) {
      case 'طبيعي': return 0xFF00c853;
      case 'منخفض': return 0xFF2196f3;
      case 'مرتفع قليلاً': return 0xFFff9800;
      default: return 0xFFf44336;
    }
  }
}

// ── Reminder ──
class Reminder {
  final int? id;
  final String type; // 'glucose' | 'bp' | 'med'
  final String label;
  final String time; // HH:MM
  final String? whenTaken;
  final bool enabled;
  final int notifId;

  Reminder({
    this.id, required this.type, required this.label,
    required this.time, this.whenTaken, required this.enabled,
    required this.notifId,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'type': type, 'label': label, 'time': time,
    'when_taken': whenTaken, 'enabled': enabled ? 1 : 0,
    'notif_id': notifId,
  };

  static Reminder fromMap(Map<String, dynamic> m) => Reminder(
    id: m['id'], type: m['type'], label: m['label'],
    time: m['time'], whenTaken: m['when_taken'],
    enabled: m['enabled'] == 1, notifId: m['notif_id'],
  );

  Reminder copyWith({bool? enabled, String? time, String? label}) => Reminder(
    id: id, type: type, label: label ?? this.label,
    time: time ?? this.time, whenTaken: whenTaken,
    enabled: enabled ?? this.enabled, notifId: notifId,
  );
}

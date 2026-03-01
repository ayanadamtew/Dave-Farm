import 'package:uuid/uuid.dart';

class DailyLog {
  final String id;
  final String flockId;
  final DateTime date;
  final int goodEggs;
  final int brokenEggs;
  final int deadBirds;
  final int isSynced; // 0 = false, 1 = true

  const DailyLog({
    required this.id,
    required this.flockId,
    required this.date,
    required this.goodEggs,
    required this.brokenEggs,
    required this.deadBirds,
    this.isSynced = 0,
  });

  /// Create a new DailyLog with an auto-generated UUIDv4.
  factory DailyLog.create({
    required String flockId,
    required DateTime date,
    required int goodEggs,
    required int brokenEggs,
    required int deadBirds,
  }) {
    return DailyLog(
      id: const Uuid().v4(),
      flockId: flockId,
      date: date,
      goodEggs: goodEggs,
      brokenEggs: brokenEggs,
      deadBirds: deadBirds,
      isSynced: 0,
    );
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'] as String,
      flockId: map['flock_id'] as String,
      date: DateTime.parse(map['date'] as String),
      goodEggs: map['good_eggs'] as int,
      brokenEggs: map['broken_eggs'] as int,
      deadBirds: map['dead_birds'] as int,
      isSynced: map['is_synced'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flock_id': flockId,
      'date': date.toIso8601String(),
      'good_eggs': goodEggs,
      'broken_eggs': brokenEggs,
      'dead_birds': deadBirds,
      'is_synced': isSynced,
    };
  }

  DailyLog copyWith({
    String? id,
    String? flockId,
    DateTime? date,
    int? goodEggs,
    int? brokenEggs,
    int? deadBirds,
    int? isSynced,
  }) {
    return DailyLog(
      id: id ?? this.id,
      flockId: flockId ?? this.flockId,
      date: date ?? this.date,
      goodEggs: goodEggs ?? this.goodEggs,
      brokenEggs: brokenEggs ?? this.brokenEggs,
      deadBirds: deadBirds ?? this.deadBirds,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() =>
      'DailyLog(id: $id, flockId: $flockId, date: $date, goodEggs: $goodEggs, deadBirds: $deadBirds)';
}

import 'package:uuid/uuid.dart';

class Flock {
  final String id;
  final String name;
  final DateTime startDate;
  final int initialBirdCount;
  final int currentBirdCount;
  final String breed;
  final int isSynced; // 0 = false, 1 = true

  const Flock({
    required this.id,
    required this.name,
    required this.startDate,
    required this.initialBirdCount,
    required this.currentBirdCount,
    required this.breed,
    this.isSynced = 0,
  });

  /// Create a new Flock with an auto-generated UUIDv4.
  factory Flock.create({
    required String name,
    required DateTime startDate,
    required int initialBirdCount,
    required String breed,
  }) {
    return Flock(
      id: const Uuid().v4(),
      name: name,
      startDate: startDate,
      initialBirdCount: initialBirdCount,
      currentBirdCount: initialBirdCount,
      breed: breed,
      isSynced: 0,
    );
  }

  factory Flock.fromMap(Map<String, dynamic> map) {
    return Flock(
      id: map['id'] as String,
      name: map['name'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      initialBirdCount: map['initial_bird_count'] as int,
      currentBirdCount: map['current_bird_count'] as int,
      breed: map['breed'] as String,
      isSynced: map['is_synced'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'initial_bird_count': initialBirdCount,
      'current_bird_count': currentBirdCount,
      'breed': breed,
      'is_synced': isSynced,
    };
  }

  Flock copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    int? initialBirdCount,
    int? currentBirdCount,
    String? breed,
    int? isSynced,
  }) {
    return Flock(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      initialBirdCount: initialBirdCount ?? this.initialBirdCount,
      currentBirdCount: currentBirdCount ?? this.currentBirdCount,
      breed: breed ?? this.breed,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() =>
      'Flock(id: $id, name: $name, currentBirdCount: $currentBirdCount)';
}

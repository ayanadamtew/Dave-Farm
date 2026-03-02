import 'package:uuid/uuid.dart';

class Expense {
  final String id;
  final DateTime date;
  final String category;
  final double amount;
  final String? notes;
  final int isSynced; // 0 = false, 1 = true

  const Expense({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    this.notes,
    this.isSynced = 0,
  });

  /// Create a new Expense with an auto-generated UUIDv4.
  factory Expense.create({
    required DateTime date,
    required String category,
    required double amount,
    String? notes,
  }) {
    return Expense(
      id: const Uuid().v4(),
      date: date,
      category: category,
      amount: amount,
      notes: notes,
      isSynced: 0,
    );
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      isSynced: map['is_synced'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'category': category,
      'amount': amount,
      'notes': notes,
      'is_synced': isSynced,
    };
  }

  Expense copyWith({
    String? id,
    DateTime? date,
    String? category,
    double? amount,
    String? notes,
    int? isSynced,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() =>
      'Expense(id: $id, category: $category, amount: $amount)';
}

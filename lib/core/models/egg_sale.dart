import 'package:uuid/uuid.dart';

class EggSale {
  final String id;
  final String customerName;
  final DateTime date;
  final int quantity;
  final double unitPrice;
  final double totalPrice; // auto-calculated: quantity * unitPrice
  final int isSynced; // 0 = false, 1 = true

  const EggSale({
    required this.id,
    required this.customerName,
    required this.date,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.isSynced = 0,
  });

  /// Create a new EggSale with auto-calculated totalPrice and UUIDv4.
  factory EggSale.create({
    required String customerName,
    required DateTime date,
    required int quantity,
    required double unitPrice,
  }) {
    return EggSale(
      id: const Uuid().v4(),
      customerName: customerName,
      date: date,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: quantity * unitPrice,
      isSynced: 0,
    );
  }

  factory EggSale.fromMap(Map<String, dynamic> map) {
    return EggSale(
      id: map['id'] as String,
      customerName: map['customer_name'] as String,
      date: DateTime.parse(map['date'] as String),
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      isSynced: map['is_synced'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'date': date.toIso8601String(),
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'is_synced': isSynced,
    };
  }

  EggSale copyWith({
    String? id,
    String? customerName,
    DateTime? date,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    int? isSynced,
  }) {
    return EggSale(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() =>
      'EggSale(id: $id, customer: $customerName, qty: $quantity, total: $totalPrice)';
}

import 'package:equatable/equatable.dart';

class BudgetModel extends Equatable {
  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.month,
    required this.limitAmount,
    required this.usedAmount,
  });

  final int? id;
  final int categoryId;
  final DateTime month;
  final double limitAmount;
  final double usedAmount;

  double get usageRatio => limitAmount == 0 ? 0 : (usedAmount / limitAmount).clamp(0, 1);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'month': month.toIso8601String(),
      'limit_amount': limitAmount,
      'used_amount': usedAmount,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      month: DateTime.parse(map['month'] as String),
      limitAmount: (map['limit_amount'] as num).toDouble(),
      usedAmount: (map['used_amount'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, categoryId, month, limitAmount, usedAmount];
}

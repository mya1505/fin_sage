import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

class TransactionModel extends Equatable {
  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.type,
  });

  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final int categoryId;
  final TransactionType type;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'type': type.name,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      categoryId: map['category_id'] as int,
      type: TransactionType.values.byName(map['type'] as String),
    );
  }

  @override
  List<Object?> get props => [id, title, amount, date, categoryId, type];
}

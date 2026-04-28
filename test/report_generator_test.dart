import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:fin_sage/features/reports/report_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final generator = ReportGenerator();

  final items = [
    TransactionModel(
      id: 1,
      title: 'Salary',
      amount: 15000000,
      date: DateTime(2026, 4, 10),
      categoryId: 1,
      type: TransactionType.income,
    ),
    TransactionModel(
      id: 2,
      title: 'Groceries',
      amount: 500000,
      date: DateTime(2026, 4, 12),
      categoryId: 1,
      type: TransactionType.expense,
    ),
  ];

  test('generateCsv should include header and rows', () async {
    final csv = await generator.generateCsv(items);

    expect(csv, contains('id,title,amount,type,date,category_id'));
    expect(csv, contains('Salary'));
    expect(csv, contains('Groceries'));
  });

  test('generatePdf should return non-empty bytes', () async {
    final pdf = await generator.generatePdf(items, title: 'Test Report');

    expect(pdf, isNotEmpty);
    expect(pdf.length, greaterThan(100));
  });
}

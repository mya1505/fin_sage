import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportContentLabels {
  const ReportContentLabels({
    required this.csvHeaderId,
    required this.csvHeaderTitle,
    required this.csvHeaderAmount,
    required this.csvHeaderType,
    required this.csvHeaderDate,
    required this.csvHeaderCategoryId,
    required this.transactionTypeIncome,
    required this.transactionTypeExpense,
    required this.pdfDefaultTitle,
    required this.pdfTransactionsLabel,
    required this.pdfIncomeLabel,
    required this.pdfExpenseLabel,
    required this.pdfNetBalanceLabel,
  });

  const ReportContentLabels.english()
      : csvHeaderId = 'id',
        csvHeaderTitle = 'title',
        csvHeaderAmount = 'amount',
        csvHeaderType = 'type',
        csvHeaderDate = 'date',
        csvHeaderCategoryId = 'category_id',
        transactionTypeIncome = 'Income',
        transactionTypeExpense = 'Expense',
        pdfDefaultTitle = 'FinSage Financial Report',
        pdfTransactionsLabel = 'Transactions',
        pdfIncomeLabel = 'Income',
        pdfExpenseLabel = 'Expense',
        pdfNetBalanceLabel = 'Net Balance';

  final String csvHeaderId;
  final String csvHeaderTitle;
  final String csvHeaderAmount;
  final String csvHeaderType;
  final String csvHeaderDate;
  final String csvHeaderCategoryId;
  final String transactionTypeIncome;
  final String transactionTypeExpense;
  final String pdfDefaultTitle;
  final String pdfTransactionsLabel;
  final String pdfIncomeLabel;
  final String pdfExpenseLabel;
  final String pdfNetBalanceLabel;

  String transactionTypeLabel(TransactionType type) {
    return type == TransactionType.income ? transactionTypeIncome : transactionTypeExpense;
  }
}

class ReportGenerator {
  Future<String> generateCsv(
    List<TransactionModel> items, {
    ReportContentLabels labels = const ReportContentLabels.english(),
  }) async {
    final rows = <List<dynamic>>[
      [
        labels.csvHeaderId,
        labels.csvHeaderTitle,
        labels.csvHeaderAmount,
        labels.csvHeaderType,
        labels.csvHeaderDate,
        labels.csvHeaderCategoryId,
      ],
      ...items.map(
        (e) => [
          e.id,
          e.title,
          e.amount,
          labels.transactionTypeLabel(e.type),
          e.date.toIso8601String(),
          e.categoryId,
        ],
      ),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  Future<File> exportCsvFile(
    List<TransactionModel> items, {
    ReportContentLabels labels = const ReportContentLabels.english(),
  }) async {
    final csv = await generateCsv(items, labels: labels);
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/finsage-report-$timestamp.csv');
    await file.writeAsString(csv, flush: true);
    return file;
  }

  Future<Uint8List> generatePdf(
    List<TransactionModel> items, {
    String? title,
    ReportContentLabels labels = const ReportContentLabels.english(),
  }) async {
    final income = items
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expense = items
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final balance = income - expense;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title ?? labels.pdfDefaultTitle, style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 16),
              pw.Text('${labels.pdfTransactionsLabel}: ${items.length}'),
              pw.Text('${labels.pdfIncomeLabel}: ${income.toStringAsFixed(2)}'),
              pw.Text('${labels.pdfExpenseLabel}: ${expense.toStringAsFixed(2)}'),
              pw.Text('${labels.pdfNetBalanceLabel}: ${balance.toStringAsFixed(2)}'),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 6),
              ...items.map(
                (e) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text(
                    '${e.date.toIso8601String().split('T').first} - ${e.title} - ${labels.transactionTypeLabel(e.type)} - ${e.amount.toStringAsFixed(2)}',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }
}

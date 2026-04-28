import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportGenerator {
  Future<String> generateCsv(List<TransactionModel> items) async {
    final rows = <List<dynamic>>[
      ['id', 'title', 'amount', 'type', 'date', 'category_id'],
      ...items.map(
        (e) => [e.id, e.title, e.amount, e.type.name, e.date.toIso8601String(), e.categoryId],
      ),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  Future<File> exportCsvFile(List<TransactionModel> items) async {
    final csv = await generateCsv(items);
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/finsage-report-$timestamp.csv');
    await file.writeAsString(csv, flush: true);
    return file;
  }

  Future<Uint8List> generatePdf(List<TransactionModel> items, {String? title}) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title ?? 'FinSage Financial Report', style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 16),
              ...items.map(
                (e) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text('${e.date.toIso8601String()} - ${e.title} - ${e.amount}'),
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

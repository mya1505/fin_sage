import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:fin_sage/core/constants/app_constants.dart';

class DriftQueryService extends DatabaseConnectionUser {
  DriftQueryService()
      : super(
          DatabaseConnection.fromExecutor(
            SqfliteQueryExecutor.inDatabaseFolder(path: AppConstants.dbName),
          ),
        );

  Future<Map<String, double>> monthlySummary() async {
    const query = '''
      SELECT
        SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) AS income,
        SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS expense
      FROM transactions
      WHERE substr(date, 1, 7) = substr(date('now'), 1, 7)
    ''';

    final row = await customSelect(query).getSingleOrNull();
    if (row == null) {
      return {'income': 0, 'expense': 0};
    }

    return {
      'income': (row.read<double?>('income') ?? 0),
      'expense': (row.read<double?>('expense') ?? 0),
    };
  }
}

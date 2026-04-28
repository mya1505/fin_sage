import 'package:fin_sage/data/datasources/local/auto_backup_telemetry_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('markFailure truncates long error payload to max length', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = SharedPrefsAutoBackupTelemetryStorage(prefs);

    final longError = 'x' * 1200;
    await storage.markFailure(DateTime(2026, 4, 28, 10, 0), longError);

    final telemetry = await storage.loadTelemetry();
    expect(telemetry.lastError, isNotNull);
    expect(telemetry.lastError!.length, 500);
  });

  test('markSuccess clears previous error', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = SharedPrefsAutoBackupTelemetryStorage(prefs);

    await storage.markFailure(DateTime(2026, 4, 28, 10, 0), 'network timeout');
    await storage.markSuccess(DateTime(2026, 4, 28, 10, 5));

    final telemetry = await storage.loadTelemetry();
    expect(telemetry.lastError, isNull);
    expect(telemetry.lastSuccessAt, isNotNull);
  });
}

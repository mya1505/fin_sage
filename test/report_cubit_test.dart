import 'package:fin_sage/core/errors/app_exception.dart';
import 'package:fin_sage/logic/reports/report_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('run maps app exception to stable error code', () async {
    final cubit = ReportCubit();
    addTearDown(cubit.close);

    await cubit.run(
      () async => throw const AppException('No data to export', code: 'no_data_to_export'),
    );

    expect(cubit.state.loading, false);
    expect(cubit.state.success, false);
    expect(cubit.state.error, 'no_data_to_export');
  });
}

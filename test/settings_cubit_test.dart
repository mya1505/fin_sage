import 'package:fin_sage/data/repositories/backup_repository.dart';
import 'package:fin_sage/logic/settings/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBackupRepository extends Mock implements BackupRepository {}

void main() {
  late MockBackupRepository repo;
  late SettingsCubit cubit;

  setUp(() {
    repo = MockBackupRepository();
    cubit = SettingsCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('backupNow should toggle loading state', () async {
    when(() => repo.backupNow()).thenAnswer((_) async {});

    await cubit.backupNow();

    expect(cubit.state.backupInProgress, false);
    verify(() => repo.backupNow()).called(1);
  });
}

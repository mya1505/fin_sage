import 'package:fin_sage/core/constants/app_constants.dart';
import 'package:workmanager/workmanager.dart';

class BackupScheduler {
  static const String taskName = 'finsage.auto_backup';

  static Future<void> initialize() async {
    await Workmanager().initialize(_callbackDispatcher, isInDebugMode: false);
  }

  static Future<void> scheduleEvery24Hours() async {
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: AppConstants.autoBackupInterval,
      initialDelay: const Duration(minutes: 10),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}

@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return Future<bool>.value(true);
  });
}

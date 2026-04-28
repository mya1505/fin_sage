import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BudgetNotificationService {
  BudgetNotificationService(this._notifications);

  final FlutterLocalNotificationsPlugin _notifications;

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(settings);
  }

  Future<void> notifyBudgetExceeded({required int budgetId}) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'budget_alerts',
        'Budget Alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _notifications.show(
      budgetId,
      'Budget Warning',
      'A budget has exceeded its limit.',
      details,
    );
  }
}

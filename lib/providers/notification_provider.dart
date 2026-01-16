import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

final notificationIntervalProvider =
    NotifierProvider<NotificationIntervalNotifier, int?>(
  () => NotificationIntervalNotifier(),
);

class NotificationIntervalNotifier extends Notifier<int?> {
  static const _key = 'reminder_interval';

  @override
  int? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_key)) {
      state = prefs.getInt(_key);
    }
  }

  Future<void> setInterval(int? seconds) async {
    state = seconds;
    final prefs = await SharedPreferences.getInstance();
    
    if (seconds == null || seconds <= 0) {
      await prefs.remove(_key);
      await NotificationService().cancelReminders();
    } else {
      await prefs.setInt(_key, seconds);
      // We schedule it immediately upon setting
      await NotificationService().scheduleRepeatingReminder(seconds);
    }
  }
}

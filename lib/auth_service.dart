import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authServiceProvider = AsyncNotifierProvider<AuthService, bool>(() {
  return AuthService();
});

class AuthService extends AsyncNotifier<bool> {
  static const _kLoggedInKey = 'isLoggedIn';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLoggedInKey) ?? false;
  }

  Future<void> login() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedInKey, true);
    state = const AsyncData(true);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedInKey, false);
    state = const AsyncData(false);
  }
}

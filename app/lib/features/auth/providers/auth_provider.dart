import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// holds the currently selected user id
class AuthNotifier extends Notifier<String?> {
  static const _key = 'selected_user';

  @override
  String? build() {
    _loadFromPrefs();
    return null;
  }

  void selectUser(String userId) {
    state = userId;
    _saveToPrefs(userId);
  }

  void logout() {
    state = null;
    _clearPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) state = saved;
  }

  Future<void> _saveToPrefs(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, userId);
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final authProvider = NotifierProvider<AuthNotifier, String?>(() => AuthNotifier());

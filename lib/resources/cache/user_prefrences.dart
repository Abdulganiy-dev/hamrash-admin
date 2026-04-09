import 'package:shared_preferences/shared_preferences.dart';

class UserPreference {
  static UserPreference? instance;
  SharedPreferences preferences;

  UserPreference({required this.preferences});

  static Future<UserPreference> getInstance() async {
    if (instance != null) {
      return instance!;
    } else {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      instance = UserPreference(preferences: preferences);
      return instance!;
    }
  }

  static const _canUseHapticFeedback = 'canUseHapticFeedback';
  static const _isLoggedIn = 'isLoggedIn';

  bool get canUseHapticFeedback => preferences.getBool(_canUseHapticFeedback) ?? true;

  void setCanUseHapticFeedback(bool value) {
    preferences.setBool(_canUseHapticFeedback, value);
  }

  bool get isLoggedIn => preferences.getBool(_isLoggedIn) ?? false;

  Future<void> setIsLoggedIn(bool value) async {
    await preferences.setBool(_isLoggedIn, value);
  }

  Future<void> clearLoginState() async {
    await preferences.remove(_isLoggedIn);
  }
}

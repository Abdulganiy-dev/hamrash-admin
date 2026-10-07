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

  bool get canUseHapticFeedback => preferences.getBool(_canUseHapticFeedback) ?? true;

  void setCanUseHapticFeedback(bool value) {
    preferences.setBool(_canUseHapticFeedback, value);
  }
}

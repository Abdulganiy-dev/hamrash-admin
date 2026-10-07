
import 'package:hamrash_admin/core/app_logger.dart';
import 'package:hamrash_admin/core/cache/user_prefrences.dart';

import 'package:haptic_feedback/haptic_feedback.dart';

class HapticHelpers {
  HapticHelpers._(); // Private constructor

  static bool _canVibrate = false;
  static UserPreference? _preference;
  static bool _initialized = false;

  // Call this once when your app starts
  static Future<void> initialize() async {
    if (!_initialized) {
      _preference = await UserPreference.getInstance();
      _canVibrate = _preference!.canUseHapticFeedback;

      // Check if device supports haptics
      final bool canVibrate = await Haptics.canVibrate();
      AppLogger.info("Device supports haptics: $canVibrate");
      AppLogger.info("User preference allows vibration: $_canVibrate");

      _initialized = true;
    }
  }

  // Update this when user changes the setting
  static Future<void> updateVibrationStatus() async {
    _canVibrate = await checkSavedVibrationStatus();

    AppLogger.info("Vibration status updated: $_canVibrate");
  }

  static Future<bool> checkSavedVibrationStatus() async {
    _preference ??= await UserPreference.getInstance();
    final bool vibStatus = _preference!.canUseHapticFeedback;
    _canVibrate = vibStatus;
    return vibStatus;
  }

  static Future<void> setEnabled(bool enabled) async {
    if (!_initialized) {
      await initialize();
    }
    _preference ??= await UserPreference.getInstance();
    _preference!.setCanUseHapticFeedback(enabled);
    _canVibrate = enabled;
    AppLogger.info("Haptic feedback ${enabled ? 'enabled' : 'disabled'}");
  }

  static Future<void> vibrate(VibrationType type) async {
    // Ensure initialized
    if (!_initialized) {
      await initialize();
    }
    final bool canVibrate = await Haptics.canVibrate();
    AppLogger.info("Device supports haptics: $canVibrate");
    AppLogger.info(
      "Attempting vibration. Can vibrate: $_canVibrate, Type: $type",
    );

    if (!_canVibrate) {
      AppLogger.info("Vibration disabled by user preference");
      return;
    }

    try {
      switch (type) {
        case VibrationType.medium:
          await Haptics.vibrate(HapticsType.medium);
          break;
        case VibrationType.hard:
          await Haptics.vibrate(HapticsType.heavy);
          break;
        case VibrationType.light:
          await Haptics.vibrate(HapticsType.light);
          break;
        case VibrationType.selection:
          await Haptics.vibrate(HapticsType.selection);
          break;
        case VibrationType.vibrate:
          // Standard vibration - using heavy for noticeable feedback
          await Haptics.vibrate(HapticsType.heavy);
          break;
      }
      AppLogger.info("Vibration triggered successfully: $type");
    } catch (e) {
      AppLogger.error("Haptic feedback error: $e");
    }
  }
}

// Keep your original enum order
enum VibrationType { medium, hard, light, selection, vibrate }

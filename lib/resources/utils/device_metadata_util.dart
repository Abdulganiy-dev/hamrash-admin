import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceMetadataBundle {
  const DeviceMetadataBundle({
    required this.appMetadata,
    required this.deviceMetadata,
  });

  final Map<String, dynamic> appMetadata;
  final Map<String, dynamic> deviceMetadata;

  Map<String, dynamic> compose({
    required bool includeAppContext,
    required bool includeDeviceContext,
  }) {
    final metadata = <String, dynamic>{};
    if (includeAppContext) {
      metadata.addAll(appMetadata);
    }
    if (includeDeviceContext) {
      metadata.addAll(deviceMetadata);
    }
    return metadata;
  }
}

class DeviceMetadataUtil {
  static Future<DeviceMetadataBundle> collectBundle() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final timezone = DateTime.now().timeZoneName;

    final appMetadata = <String, dynamic>{
      'app_version': packageInfo.version,
      'app_build': packageInfo.buildNumber,
    };

    final deviceMetadata = <String, dynamic>{
      'platform': Platform.operatingSystem,
      'locale': locale.toString(),
      'timezone': timezone,
      'device_system_version': Platform.operatingSystemVersion,
      'device_model': await _getDeviceModel(),
    };

    return DeviceMetadataBundle(
      appMetadata: appMetadata,
      deviceMetadata: deviceMetadata,
    );
  }

  static Future<String> _getDeviceModel() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return info.utsname.machine;
      }
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return info.model;
      }
      if (Platform.isMacOS) {
        final info = await plugin.macOsInfo;
        return info.model;
      }
    } catch (_) {
      // Ignore and use fallback below.
    }
    return 'unknown';
  }
}

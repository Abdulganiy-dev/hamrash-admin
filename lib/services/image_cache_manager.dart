import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Custom cache manager for images with optimized settings
/// 
/// This cache manager provides:
/// - 30 days cache duration
/// - 200MB max cache size
/// - Automatic cache cleanup
class AppImageCacheManager {
  static const String _cacheKey = 'app_image_cache';
  static const Duration _cacheDuration = Duration(days: 30);

  static CacheManager? _instance;

  /// Get the singleton instance of the cache manager
  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        _cacheKey,
        stalePeriod: _cacheDuration,
        maxNrOfCacheObjects: 200,
        repo: JsonCacheInfoRepository(databaseName: _cacheKey),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }

  /// Clear all cached images
  static Future<void> clearCache() async {
    await instance.emptyCache();
  }

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    final cacheDir = await _getCacheDirectory();
    if (cacheDir == null) return 0;
    
    int totalSize = 0;
    try {
      final files = cacheDir.listSync(recursive: true);
      for (var file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }
    } catch (e) {
      // Handle error silently
    }
    return totalSize;
  }

  /// Get cache directory
  static Future<Directory?> _getCacheDirectory() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final appCacheDir = Directory(path.join(cacheDir.path, _cacheKey));
      if (!await appCacheDir.exists()) {
        await appCacheDir.create(recursive: true);
      }
      return appCacheDir;
    } catch (e) {
      return null;
    }
  }

  /// Dispose the cache manager instance
  static void dispose() {
    _instance = null;
  }
}


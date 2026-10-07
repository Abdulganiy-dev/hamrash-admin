import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resolves a stored local file path to one valid for the CURRENT app launch.
///
/// iOS (and app updates in general) can change the app's container path — the
/// `.../Containers/Data/Application/<UUID>/…` prefix — between launches, so an
/// absolute path we persisted earlier may no longer resolve even though the
/// file still lives in the documents directory. When the stored path is
/// missing, we rebase its filename onto the current documents directory.
///
/// Returns a usable absolute path, or null if the file can't be found.
Future<String?> resolveLocalFilePath(String? stored) async {
  if (stored == null || stored.isEmpty) return null;
  if (File(stored).existsSync()) return stored;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final candidate = '${dir.path}/${stored.split('/').last}';
    if (File(candidate).existsSync()) return candidate;
  } catch (_) {
    // fall through
  }
  return null;
}

/// Deletes a locally-stored file we created, resolving stale paths first so it
/// still works after an app relaunch/update changed the container path.
///
/// [requiredMarker] guards against deleting arbitrary files — the stored path
/// must contain it (e.g. 'profile_photo_'). No-op when the marker is absent or
/// the file can't be found.
Future<void> deleteLocalFile(String? path, {String? requiredMarker}) async {
  if (path == null || path.isEmpty) return;
  if (requiredMarker != null && !path.contains(requiredMarker)) return;
  final resolved = await resolveLocalFilePath(path);
  if (resolved == null) return;
  try {
    await File(resolved).delete();
  } catch (_) {
    // best effort
  }
}

/// Reads a local image file (resolving stale paths first) and returns it as a
/// `data:` URL, or null if the file can't be found or read.
Future<String?> fileToDataUrl(String? path) async {
  final resolved = await resolveLocalFilePath(path);
  if (resolved == null) return null;
  try {
    final bytes = await File(resolved).readAsBytes();
    final mime = resolved.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  } catch (_) {
    return null;
  }
}

/// Reads several local image files into `data:` URLs, skipping any that can't
/// be found or read.
Future<List<String>> filesToDataUrls(Iterable<String?> paths) async {
  final urls = <String>[];
  for (final path in paths) {
    final url = await fileToDataUrl(path);
    if (url != null) urls.add(url);
  }
  return urls;
}

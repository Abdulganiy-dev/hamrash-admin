import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_kind.dart';

/// The `media-upload` function refuses any app or kind it doesn't list. Its
/// allow-list lives in this repo, so this reads it and fails if the app's
/// [MediaKind] ever drifts from it (a new kind here but not there would only
/// show up as a 400 on a phone).
void main() {
  test('every MediaKind is on the function allow-list, and nothing else is', () {
    final source = File(
      'supabase/functions/_shared/media_upload.mjs',
    ).readAsStringSync();

    final entry = RegExp(
      "'${MediaKind.appName}':\\s*\\[([^\\]]*)\\]",
    ).firstMatch(source);
    expect(
      entry,
      isNotNull,
      reason: "'${MediaKind.appName}' is missing from ALLOWED_KINDS",
    );

    final allowed = RegExp("'([a-z-]+)'")
        .allMatches(entry!.group(1)!)
        .map((m) => m.group(1)!)
        .toSet();

    expect(MediaKind.values.map((k) => k.path).toSet(), allowed);
  });

  test('the app name is the one the function knows this app by', () {
    expect(MediaKind.appName, 'hamrash-admin');
  });
}

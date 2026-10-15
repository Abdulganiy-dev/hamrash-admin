import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/image_service.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_kind.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_upload_service.dart';
import 'package:hamrash_admin/singleton_locator/locator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Headers, MultipartFile;

/// Records what is sent to the one-time upload URL.
class _Recorder implements HttpClientAdapter {
  String body = '';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final chunks = <int>[];
    await for (final chunk in requestStream ?? const Stream<Uint8List>.empty()) {
      chunks.addAll(chunk);
    }
    body = latin1.decode(chunks);
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Recorder upload;
  late List<Map<String, dynamic>> reservations;

  setUp(() {
    upload = _Recorder();
    reservations = [];
    final client = SupabaseClient(
      'https://project.supabase.co',
      'sb_publishable_test',
      accessToken: () async => 'clerk-jwt',
      httpClient: MockClient((request) async {
        reservations.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response(
          jsonEncode({'id': 'id-1', 'uploadURL': 'https://u.example/1', 'url': 'https://cdn.example/1'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    locator
      ..reset()
      ..registerSingleton<MediaUploadService>(
        MediaUploadService(client, dio: Dio()..httpClientAdapter = upload),
      );
  });

  tearDown(() => locator.reset());

  final bytes = Uint8List.fromList(utf8.encode('DATA'));

  test('images keep their extension', () async {
    await ImageService().uploadImage(bytes, 'logo.jpg', kind: MediaKind.schoolLogo);
    expect(upload.body, contains('filename="logo.jpg"'));
    expect(reservations.single['type'], 'image');
  });

  test('an image name without an extension becomes .png', () async {
    await ImageService().uploadImage(bytes, 'logo', kind: MediaKind.schoolLogo);
    expect(upload.body, contains('filename="logo.png"'));
  });

}

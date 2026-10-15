import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/api/models/cloudflare_models/cloudflare_errors.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_kind.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_upload_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Headers, MultipartFile;

/// Stands in for Cloudflare's one-time upload URL.
class _FakeUploadServer implements HttpClientAdapter {
  _FakeUploadServer({this.status = 200, this.offline = false});

  final int status;
  final bool offline;
  RequestOptions? request;
  String body = '';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    final chunks = <int>[];
    await for (final chunk in requestStream ?? const Stream<Uint8List>.empty()) {
      chunks.addAll(chunk);
    }
    body = latin1.decode(chunks);
    return ResponseBody.fromString('{"success":true}', status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

const _reservation = {
  'id': 'hamrash-admin/dev/school-logos/uuid-1',
  'uploadURL': 'https://upload.example/one-time',
  'url':
      'https://imagedelivery.net/hash/hamrash-admin/dev/school-logos/uuid-1/public',
};

void main() {
  late http.Request functionCall;

  MediaUploadService service({
    required http.Response Function(http.Request) function,
    _FakeUploadServer? upload,
  }) {
    final client = SupabaseClient(
      'https://project.supabase.co',
      'sb_publishable_test',
      accessToken: () async => 'clerk-jwt',
      httpClient: MockClient((request) async {
        functionCall = request;
        return function(request);
      }),
    );
    final dio = Dio()..httpClientAdapter = upload ?? _FakeUploadServer();
    return MediaUploadService(client, dio: dio);
  }

  http.Response ok() => http.Response(
    jsonEncode(_reservation),
    200,
    headers: {'content-type': 'application/json'},
  );

  Future<UploadedMedia> uploadLogo(MediaUploadService s) => s.upload(
    isVideo: false,
    bytes: Uint8List.fromList(utf8.encode('PNGDATA')),
    filename: 'logo.png',
    kind: MediaKind.schoolLogo,
  );

  test('asks the function for an image upload as the signed-in user', () async {
    final s = service(function: (_) => ok());
    await uploadLogo(s);

    expect(functionCall.url.path, '/functions/v1/media-upload');
    expect(functionCall.headers['Authorization'], 'Bearer clerk-jwt');
    expect(jsonDecode(functionCall.body), {
      'type': 'image',
      'app': 'hamrash-admin',
      'kind': 'school-logos',
    });
  });

  test('asks for a video when isVideo is set', () async {
    final s = service(function: (_) => ok());
    await s.upload(
      isVideo: true,
      bytes: Uint8List(3),
      filename: 'clip.mp4',
      kind: MediaKind.schoolLogo,
    );
    expect(jsonDecode(functionCall.body)['type'], 'video');
  });

  test('sends the file to the one-time URL and returns the id and URL', () async {
    final upload = _FakeUploadServer();
    final media = await uploadLogo(
      service(function: (_) => ok(), upload: upload),
    );

    expect(media.id, _reservation['id']);
    expect(media.url, _reservation['url']);
    expect(upload.request!.uri.toString(), 'https://upload.example/one-time');
    expect(upload.request!.method, 'POST');
    expect(upload.body, contains('name="file"'));
    expect(upload.body, contains('filename="logo.png"'));
    expect(upload.body, contains('PNGDATA'));
  });

  test('never sends the Clerk token to Cloudflare', () async {
    final upload = _FakeUploadServer();
    await uploadLogo(service(function: (_) => ok(), upload: upload));
    expect(upload.request!.headers.containsKey('Authorization'), isFalse);
  });

  group('failures become CloudflareException', () {
    Future<CloudflareException> failure(MediaUploadService s) async {
      try {
        await uploadLogo(s);
      } on CloudflareException catch (e) {
        return e;
      }
      fail('expected a CloudflareException');
    }

    test('the function refusing keeps its status', () async {
      for (final status in [400, 401, 502]) {
        final e = await failure(
          service(function: (_) => http.Response('{}', status)),
        );
        expect(e.statusCode, status);
      }
    });

    test('no connection to the function', () async {
      final e = await failure(
        service(function: (_) => throw http.ClientException('offline')),
      );
      expect(e.type, CloudflareError.noHTTPResponse);
    });

    test('an answer that is not a reservation', () async {
      for (final body in ['"nope"', '{"id":"x"}', '{"id":1,"uploadURL":2,"url":3}']) {
        final e = await failure(
          service(
            function: (_) => http.Response(
              body,
              200,
              headers: {'content-type': 'application/json'},
            ),
          ),
        );
        expect(e.type, CloudflareError.unableToParse, reason: body);
      }
    });

    test('Cloudflare refuses the upload', () async {
      final e = await failure(
        service(
          function: (_) => ok(),
          upload: _FakeUploadServer(status: 413),
        ),
      );
      expect(e.type, CloudflareError.httpError);
      expect(e.statusCode, 413);
    });

    test('no connection to Cloudflare', () async {
      final e = await failure(
        service(function: (_) => ok(), upload: _FakeUploadServer(offline: true)),
      );
      expect(e.type, CloudflareError.noHTTPResponse);
    });
  });
}


import 'package:hamrash_admin/api/api_setup/from_json.dart';
import 'package:hamrash_admin/services/error_logger_service.dart';

/// Generic response wrapper that handles parsing and error responses
///
///A function that creates an object of type [T]
typedef Create<T> = T Function();

///Construct to get object from generic class
abstract class GenericObject<T> {
  Create<FromJson> create;

  GenericObject({required this.create});

  T genericObject(dynamic data) {
    final item = create();
    return item.fromJson(data);
  }
}

///Construct to wrap response from API.
///
///Used it as return object of APIController to handle any kind of response.
class ResponseWrapper<T> extends GenericObject<T> {
  late T response;
  String? errorMessage;
  int? statusCode;
  String? status;

  ResponseWrapper({required super.create});

  Future<ResponseWrapper<T>> init(dynamic data) async {
    final wrapper = ResponseWrapper<T>(create: create);
    wrapper.response = wrapper.genericObject(data);
    return wrapper;
  }

  /// FIXED: Removed compute() isolate usage as it was causing crashes
  ///
  /// ISSUE: The compute() call was passing an instance method (init) which captures
  /// the 'create' closure. Closures and instance methods cannot be serialized across
  /// isolates, causing "Illegal argument in isolate message" errors.
  ///
  /// SOLUTION: JSON parsing is fast enough that isolate overhead isn't justified.
  /// Direct method call is simpler, more reliable, and actually faster for small payloads.
  Future<ResponseWrapper<T>> initialiseData(dynamic data) async {
    // Directly call init() instead of using compute() to avoid isolate serialization issues
    return await init(data);
  }

  /// Factory method to create a success response
  factory ResponseWrapper.onSuccess(T response) {
    final wrapper = ResponseWrapper<T>(
      create: () => throw UnimplementedError('Not needed for success response'),
    );
    wrapper.response = response;
    return wrapper;
  }

  /// Factory method to create an error response
  factory ResponseWrapper.onError({
    required Create<FromJson> create,
    required dynamic data,
    String? message,
    int? statusCode,
    String? status,
  }) {
    final wrapper = ResponseWrapper<T>(create: create);
    wrapper.response = wrapper.genericObject(data);
    wrapper.errorMessage = message;
    wrapper.statusCode = statusCode;
    wrapper.status = status;
    return wrapper;
  }

  /// Check if the response is successful
  bool get isSuccess {
    if (response is APIResponse) {
      final apiResponse = response as APIResponse;
      return apiResponse.status == '00' || apiResponse.status == 'success';
    }
    return false;
  }
}

class APIResponse<T> extends GenericObject<T>
    implements FromJson<APIResponse<T>> {
  String? status;
  String? message;
  dynamic nMeta;
  dynamic nLinks;
  T? data;

  APIResponse({required super.create});

  @override
  APIResponse<T> fromJson(dynamic json) {
    try {
      status = json['status'];
      message = json['message'];
      if (message != null &&
          message!.isNotEmpty &&
          message!.contains("exception")) {
        message = "An error occurred, please try again later.";
      }
      if (message != null &&
          message!.isNotEmpty &&
          message!.contains(
            "This indicates an error which most likely cannot be solved by the library.",
          )) {
        message = "Connection error, please check your internet connection.";
      }
      if (message != null &&
          message!.isNotEmpty &&
          message!.toLowerCase().contains("failed host lookup")) {
        message = "Connection error, please check your internet connection.";
      }

      nMeta = json['_meta'];
      nLinks = json['_links'];
      if (json['data'] != null) {
        data = genericObject(json['data']);
      }
    } catch (e, stackTrace) {
      ErrorLoggerService.logError(e.toString(), stackTrace: stackTrace);
    }
    return this;
  }
}

class APIListResponse<T> extends GenericObject<T>
    implements FromJson<APIListResponse<T>> {
  String? status;
  String? message;
  dynamic nMeta;
  dynamic nLinks;
  List<T>? data;
  bool directList;

  APIListResponse({required super.create, this.directList = false});

  @override
  APIListResponse<T> fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    nMeta = json['_meta'];
    nLinks = json['_links'];
    data = [];
    if (directList) {
      if (json['data'] != null) {
        data = json['data'].cast<String>();
      } else {
        data = null;
      }
    } else if (json['data'] != null) {
      json['data'].forEach((item) {
        data?.add(genericObject(item));
      });
    }
    return this;
  }
}

class APIProfileListResponse<T> extends GenericObject<T>
    implements FromJson<APIProfileListResponse<T>> {
  String? status;
  String? message;
  dynamic nMeta;
  dynamic nLinks;
  T? data;
  List<T>? profiles;

  bool directList;

  APIProfileListResponse({required super.create, this.directList = false});

  @override
  APIProfileListResponse<T> fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    nMeta = json['_meta'];
    nLinks = json['_links'];
    profiles = [];

    if (json['data'] != null) {
      data = genericObject(json['data']);
    }
    if (json['data']['profiles'] != null) {
      json['data']['profiles'].forEach((item) {
        profiles?.add(genericObject(item));
      });
    }

    return this;
  }
}

class ErrorResponse implements Exception {
  String? message;

  ErrorResponse({this.message});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(message: json['message'] ?? 'Something went wrong.');
  }

  @override
  String toString() {
    return message ?? 'Failed to convert message to string.';
  }
}

import 'package:flutter/material.dart';
import 'package:hamrash_admin/services/navigation_service.dart';
import 'package:hamrash_admin/widgets/error_modal.dart';

import '../resources/error_messages.dart';
import '../resources/utils/view_util.dart';
import '../services/error_logger_service.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _busy = false;
  bool get busy => _busy;
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  void setBusy(bool value) {
    if (_isDisposed) return;
    _busy = value;
    if (!_isDisposed) notifyListeners();
  }

  @protected
  Future<void> handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    String? userMessage,
    bool showSnackBar = false,
    bool showErrorModal = true,
    bool fatal = false,
    Map<String, dynamic>? customParams,
  }) async {
    setBusy(false);

    await ErrorLoggerService.logError(
      error,
      stackTrace: stackTrace,
      context: context ?? runtimeType.toString(),
      fatal: fatal,
      customParams: customParams,
    );

    if (showSnackBar) {
      ViewUtil.showSnackBar(
        userMessage ?? ErrorMessages.somethingWentWrong,
      );
    }

    if (showErrorModal) {
      ErrorModal.show(
        ViewUtil.navigatorKey.currentContext!,
        title: "Error",
        message: userMessage ?? ErrorMessages.somethingWentWrong,
      );
    }
  }

  @protected
  Future<void> handleNetworkError(
    dynamic error, {
    StackTrace? stackTrace,
    String? endpoint,
    String? method,
    int? statusCode,
    String? userMessage,
  }) async {
    setBusy(false);

    await ErrorLoggerService.logNetworkError(
      error,
      endpoint: endpoint,
      method: method,
      statusCode: statusCode,
      stackTrace: stackTrace,
    );

    ViewUtil.showSnackBar(
      userMessage ?? ErrorMessages.networkError,
    );
  }

  @protected
  Future<void> handleDatabaseError(
    dynamic error, {
    StackTrace? stackTrace,
    String? operation,
    String? tableName,
    String? userMessage,
  }) async {
    setBusy(false);

    await ErrorLoggerService.logDatabaseError(
      error,
      operation: operation,
      tableName: tableName,
      stackTrace: stackTrace,
    );

    ViewUtil.showSnackBar(
      userMessage ?? ErrorMessages.databaseError,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }
}


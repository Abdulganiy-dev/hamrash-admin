import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hamrash_admin/env_config/flavor_config.dart';
import 'package:hamrash_admin/resources/utils/view_util.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:hamrash_admin/widgets/error_modal.dart';

class SignInViewModel extends BaseViewModel {
  String title = "";
  late BuildContext context;

  String? _errorMessage;
  String? _lastShownError;

  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void init(BuildContext context) {
    this.context = context;

    addListener(_onErrorChanged);
  }

  void _onErrorChanged() {
    // Show error modal when error occurs (only once per error message)
    if (hasError && _errorMessage != null && _errorMessage != _lastShownError) {
      _lastShownError = _errorMessage;

      // Use global context to show modal
      final globalContext = ViewUtil.navigatorKey.currentContext;
      if (globalContext != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isDisposed && _errorMessage == _lastShownError) {
            ErrorModal.show(
              globalContext,
              message: _errorMessage!,
              title: 'Sign In Error',
              onDismiss: () {
                _lastShownError = null;
                clearError();
              },
            );
          }
        });
      }
    }
  }

  Future<void> signInWithGoogle() async {
    setBusy(true);
    _errorMessage = null;
    _lastShownError = null;
    notifyListeners();

    try {
      final env = FlavorConfig.instance?.envConfig();
      if (env == null) {
        throw Exception('Environment not configured');
      }

      ClerkAuth.of(context).ssoSignIn(context, .oauthGoogle);
    } catch (e, stackTrace) {
      await handleError(
        e,
        context: 'CustomSignInViewModel.signInWithGoogle',
        stackTrace: stackTrace,
        userMessage: 'Failed to sign in with Google. Please try again.',
        showSnackBar: false, // Don't show snackbar, we'll show modal instead
      );
      _errorMessage = 'Failed to sign in with Google. Please try again.';
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    _lastShownError = null;
    notifyListeners();
  }

   @override
  void dispose() {
    removeListener(_onErrorChanged);
    super.dispose();
  }
}

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:hamrash_admin/services/error_logger_service.dart';
import 'package:hamrash_admin/viewModel/base_view_model.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum SignInProvider {
  apple('Apple', clerk.Strategy.oauthApple),
  google('Google', clerk.Strategy.oauthGoogle);

  const SignInProvider(this.label, this.strategy);

  final String label;
  final clerk.Strategy strategy;
}

class SignInViewModel extends BaseViewModel {
  SignInViewModel(this._auth);

  final ClerkAuthState _auth;

  SignInProvider? _pending;
  String? _error;

  SignInProvider? get pending => _pending;
  String? get error => _error;

  Future<void> signIn(SignInProvider provider) async {
    if (_pending != null) return;

    _pending = provider;
    _error = null;
    notifyListeners();

    final clerkErrors = <clerk.ClerkError>[];
    final errorSubscription = _auth.errorStream.listen(clerkErrors.add);

    try {
      final scheme = (await PackageInfo.fromPlatform()).packageName;
      await _auth.oauthSignIn(
        strategy: provider.strategy,
        redirect: Uri.parse('$scheme://callback'),
      );

      final redirectUrl = _auth
          .client
          .signIn
          ?.firstFactorVerification
          ?.externalVerificationRedirectUrl;
      if (redirectUrl == null) {
        if (clerkErrors.isNotEmpty) throw clerkErrors.first;
        throw StateError('Clerk returned no ${provider.label} sign-in URL');
      }

      final callback = await FlutterWebAuth2.authenticate(
        url: redirectUrl,
        callbackUrlScheme: scheme,
      );
      await _auth.parseDeepLink(Uri.parse(callback));
      if (clerkErrors.isNotEmpty) throw clerkErrors.first;
    } on PlatformException catch (error, stackTrace) {
      if (error.code != 'CANCELED') {
        await _fail(provider, error, stackTrace);
      }
    } catch (error, stackTrace) {
      await _fail(provider, error, stackTrace);
    } finally {
      await errorSubscription.cancel();
      _pending = null;
      if (!isDisposed) notifyListeners();
    }
  }

  Future<void> _fail(
    SignInProvider provider,
    Object error,
    StackTrace stackTrace,
  ) async {
    await ErrorLoggerService.logError(
      error,
      stackTrace: stackTrace,
      context: 'SignIn.${provider.name}',
    );
    _error =
        'Couldn’t sign in with ${provider.label}. Check your connection and try again.';
  }
}

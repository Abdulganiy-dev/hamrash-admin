import 'package:hamrash_admin/viewModel/base_view_model.dart';

enum SignInProvider { apple, google }

class SignInViewModel extends BaseViewModel {
  SignInViewModel({this.onApplePressed, this.onGooglePressed});

  final Future<void> Function()? onApplePressed;
  final Future<void> Function()? onGooglePressed;

  SignInProvider? _pending;
  SignInProvider? get pending => _pending;

  Future<void> signIn(SignInProvider provider) async {
    if (_pending != null) return;
    final action = switch (provider) {
      SignInProvider.apple => onApplePressed,
      SignInProvider.google => onGooglePressed,
    };
    if (action == null) return;

    _pending = provider;
    notifyListeners();
    try {
      await action();
    } finally {
      _pending = null;
      notifyListeners();
    }
  }
}

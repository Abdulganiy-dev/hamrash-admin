import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../api/models/supabase_models/student_model.dart';
import '../../../api/models/supabase_models/teacher_model.dart';

/// Thrown when a claim-code redemption fails for a known business reason
/// (invalid code, already used, account already linked, etc.). The [message]
/// is the human-readable string from the DB function — safe to surface
/// directly in the UI.
class ClaimRedemptionFailure implements Exception {
  ClaimRedemptionFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thin client over the three `bind_*_claim_code` RPCs. All three share the
/// same shape: `(code, clerk_id) → binding row`, with `P0001` raises for
/// expected failures (mapped to [ClaimRedemptionFailure]).
class BindingService {
  BindingService();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const Duration _timeout = Duration(seconds: 15);

  Future<TeacherClerkBinding> bindTeacher({
    required String code,
    required String clerkId,
  }) async {
    return _bind<TeacherClerkBinding>(
      rpc: 'bind_teacher_claim_code',
      code: code,
      clerkId: clerkId,
      fromJson: (m) => TeacherClerkBinding.fromJson(m),
    );
  }

  Future<StudentClerkBinding> bindStudent({
    required String code,
    required String clerkId,
  }) async {
    return _bind<StudentClerkBinding>(
      rpc: 'bind_student_claim_code',
      code: code,
      clerkId: clerkId,
      fromJson: (m) => StudentClerkBinding.fromJson(m),
    );
  }

  Future<ParentClerkBinding> bindParent({
    required String code,
    required String clerkId,
  }) async {
    return _bind<ParentClerkBinding>(
      rpc: 'bind_parent_claim_code',
      code: code,
      clerkId: clerkId,
      fromJson: (m) => ParentClerkBinding.fromJson(m),
    );
  }

  Future<T> _bind<T>({
    required String rpc,
    required String code,
    required String clerkId,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await _supabase
          .rpc(
            rpc,
            params: {'p_code': code, 'p_clerk_id': clerkId},
          )
          .timeout(_timeout);
      return fromJson(Map<String, dynamic>.from(response as Map));
    } on PostgrestException catch (e) {
      // 'P0001' = PL/pgSQL RAISE EXCEPTION; the function's message is the
      // user-friendly explanation.
      if (e.code == 'P0001') {
        throw ClaimRedemptionFailure(e.message);
      }
      rethrow;
    }
  }
}

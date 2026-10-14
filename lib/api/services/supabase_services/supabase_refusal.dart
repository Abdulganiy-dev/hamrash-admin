import 'dart:convert';

import 'package:hamrash_admin/core/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A change the database refused, with a reason the person can act on.
class SupabaseRefusal implements Exception {
  const SupabaseRefusal(this.message);

  final String message;

  @override
  String toString() => 'SupabaseRefusal: $message';
}

/// Runs [body], logs the result as Supabase [name], and turns the database's
/// refusals into [SupabaseRefusal]s:
///
/// - [duplicate] for a name or code that's taken (23505),
/// - [inUse] for a row something else still points at (23503),
/// - [forbidden] when the person's role can't do this (42501),
/// - [invalid] when a check constraint fails (23514),
/// - our own functions' messages (P0001) as they are.
///
/// Anything else is rethrown for the caller's fallback message.
Future<T> runRefusable<T>(
  String name,
  Future<T> Function() body, {
  required Map<String, Object?> Function(T result) log,
  required String forbidden,
  String? duplicate,
  String? inUse,
  String? invalid,
}) async {
  try {
    final result = await body();
    AppLogger.info('Supabase $name result: ${jsonEncode(log(result))}');
    return result;
  } on SupabaseRefusal {
    rethrow;
  } catch (error, stackTrace) {
    AppLogger.error(
      'Supabase $name failed',
      error: error,
      stackTrace: stackTrace,
    );
    if (error is! PostgrestException) rethrow;
    final message = switch (error.code) {
      '23505' => duplicate,
      '23503' => inUse,
      '42501' => forbidden,
      '23514' => invalid,
      'P0001' => error.message,
      _ => null,
    };
    if (message == null) rethrow;
    throw SupabaseRefusal(message);
  }
}

/// Row-level security doesn't raise on a blocked update or delete; it just
/// touches no rows. Call with what came back from `.select('id')` after one.
void refuseIfNothingChanged(List<dynamic> rows, String forbidden) {
  if (rows.isEmpty) throw SupabaseRefusal(forbidden);
}

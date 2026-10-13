import 'dart:convert';

import 'package:hamrash_admin/api/models/organization_models/organization.dart';
import 'package:hamrash_admin/api/models/organization_models/setup_progress.dart';
import 'package:hamrash_admin/core/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The school itself: its details and how far its setup has got.
class SchoolService {
  SchoolService(this._supabase);

  final SupabaseClient _supabase;

  /// Saves edited details (name, address, phone, email, number_prefix,
  /// logo_id, logo_url) and returns the school as stored. Owners and admins
  /// only; the database refuses status, code and creator changes.
  Future<Organization> updateDetails(
    String organizationId,
    Map<String, Object?> changes,
  ) => _run(
    'updateDetails',
    () async => Organization.fromJson(
      await _supabase
          .from('organizations')
          .update(changes)
          .eq('id', organizationId)
          .select()
          .single(),
    ),
    log: (org) => {'id': org.id, 'changed': changes.keys.toList()},
  );

  /// Marks the details as checked, so "Check your school" doesn't come back.
  Future<Organization> confirmDetails(
    String organizationId, {
    required String clerkUserId,
  }) => updateDetails(organizationId, {
    'details_confirmed_at': DateTime.now().toUtc().toIso8601String(),
    'details_confirmed_by': clerkUserId,
  });

  /// Works out each checklist step from the school's own records.
  Future<SetupProgress> getSetupProgress(Organization organization) => _run(
    'getSetupProgress',
    () async {
      final id = organization.id;
      Future<int> count(
        String table, {
        String column = 'id',
        int limit = 1,
      }) async {
        final rows = await _supabase
            .from(table)
            .select(column)
            .eq('organization_id', id)
            .limit(limit);
        return rows.length;
      }

      final results = await Future.wait([
        _supabase
            .from('academic_terms')
            .select('id')
            .eq('organization_id', id)
            .eq('is_current', true)
            .limit(1)
            .then((rows) => rows.length),
        count('class_arms'),
        count('arm_subjects', column: 'arm_id'),
        count('grade_boundaries'),
        count('score_columns'),
        _supabase
            .from('organization_members')
            .select('id')
            .eq('organization_id', id)
            .inFilter('role', [
              'admin',
              'principal',
              'vice_principal',
              'bursar',
            ])
            .limit(1)
            .then((rows) => rows.length),
        count('students'),
        // The owner's own staff record is made when they join, so the school
        // has added staff once there are two.
        count('staff', limit: 2),
      ]);

      return SetupProgress({
        if (organization.detailsConfirmedAt != null) SetupStep.schoolDetails,
        if (results[0] > 0) SetupStep.academicCalendar,
        if (results[1] > 0) SetupStep.classes,
        if (results[2] > 0) SetupStep.subjects,
        if (results[3] > 0 && results[4] > 0) SetupStep.grading,
        if (results[5] > 0) SetupStep.team,
        if (results[6] > 0 && results[7] > 1) SetupStep.people,
      });
    },
    log: (progress) => {
      'organization_id': organization.id,
      'done': progress.done.map((step) => step.name).toList(),
    },
  );

  /// "Amina Bello", or null when the owner has no staff record or the caller
  /// can't see the school's members (bursars can't).
  Future<String?> getOwnerName(String organizationId) => _run(
    'getOwnerName',
    () async {
      final rows = await _supabase
          .from('staff')
          .select(
            'first_name, last_name, member:organization_members!staff_member_fkey!inner(role)',
          )
          .eq('organization_id', organizationId)
          .eq('member.role', 'owner')
          .limit(1);
      if (rows.isEmpty) return null;
      final row = rows.first;
      return '${row['first_name']} ${row['last_name']}'.trim();
    },
    log: (name) => {'organization_id': organizationId, 'found': name != null},
  );

  Future<T> _run<T>(
    String name,
    Future<T> Function() body, {
    required Map<String, Object?> Function(T result) log,
  }) async {
    try {
      final result = await body();
      AppLogger.info('Supabase $name result: ${jsonEncode(log(result))}');
      return result;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Supabase $name failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

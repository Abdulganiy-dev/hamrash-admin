import 'dart:convert';

import 'package:hamrash_admin/api/models/academic_calendar/calendar_draft.dart';
import 'package:hamrash_admin/core/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AcademicCalendarService {
  AcademicCalendarService(this._supabase);

  final SupabaseClient _supabase;

  String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Creates the setup calendar. A retry resumes missing term inserts.
  Future<void> createCalendar(
    String organizationId,
    CalendarDraft draft,
  ) async {
    try {
      final existing = await _supabase
          .from('academic_sessions')
          .select('id,starts_on,ends_on')
          .eq('organization_id', organizationId)
          .eq('name', draft.name)
          .limit(1);
      AppLogger.info(
        'Supabase createCalendar lookup result: ${jsonEncode({'organization_id': organizationId, 'existing_count': existing.length})}',
      );

      final String sessionId;
      if (existing.isEmpty) {
        final row = await _supabase
            .from('academic_sessions')
            .insert({
              'organization_id': organizationId,
              'name': draft.name,
              'starts_on': _day(draft.dates.start),
              'ends_on': _day(draft.dates.end),
            })
            .select('id')
            .single();
        sessionId = row['id'] as String;
        AppLogger.info(
          'Supabase createCalendar session result: ${jsonEncode({'id': sessionId})}',
        );
      } else {
        final row = existing.first;
        if (row['starts_on'] != _day(draft.dates.start) ||
            row['ends_on'] != _day(draft.dates.end)) {
          throw StateError(
            'A session named ${draft.name} already exists with different dates.',
          );
        }
        sessionId = row['id'] as String;
      }

      final saved = await _supabase
          .from('academic_terms')
          .select('id,name,sequence,starts_on,ends_on')
          .eq('organization_id', organizationId)
          .eq('session_id', sessionId);
      AppLogger.info(
        'Supabase createCalendar terms lookup result: ${jsonEncode({'session_id': sessionId, 'count': saved.length})}',
      );
      for (var i = 0; i < draft.terms.length; i++) {
        final term = draft.terms[i];
        final matches = saved.where((row) => row['sequence'] == i + 1).toList();
        if (matches.isNotEmpty) {
          final row = matches.single;
          if (row['name'] != term.name ||
              row['starts_on'] != _day(term.dates.start) ||
              row['ends_on'] != _day(term.dates.end)) {
            throw StateError(
              'Term ${i + 1} already exists with different details.',
            );
          }
          continue;
        }
        final inserted = await _supabase
            .from('academic_terms')
            .insert({
              'organization_id': organizationId,
              'session_id': sessionId,
              'name': term.name,
              'sequence': i + 1,
              'starts_on': _day(term.dates.start),
              'ends_on': _day(term.dates.end),
            })
            .select('id,name,sequence,starts_on,ends_on')
            .single();
        AppLogger.info(
          'Supabase createCalendar term result: ${jsonEncode({'id': inserted['id'], 'sequence': i + 1})}',
        );
        saved.add(inserted);
      }

      final current = saved.singleWhere(
        (row) => row['sequence'] == draft.currentTermIndex + 1,
      );
      final result = await _supabase.rpc(
        'set_current_term',
        params: {'p_term_id': current['id']},
      );
      AppLogger.info('Supabase set_current_term result: ${jsonEncode(result)}');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Supabase createCalendar failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

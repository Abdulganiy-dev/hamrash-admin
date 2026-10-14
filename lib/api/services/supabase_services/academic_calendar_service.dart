import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/academic_calendar/academic_session.dart';
import 'package:hamrash_admin/api/models/academic_calendar/calendar_draft.dart';
import 'package:hamrash_admin/core/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sessions and their terms. The database decides who may change what
/// (school leaders), keeps terms inside their session, refuses to remove the
/// current term, and keeps closed sessions read-only.
class AcademicCalendarService {
  AcademicCalendarService(this._supabase);

  final SupabaseClient _supabase;

  /// Every session at the school with its terms, newest first.
  Future<List<AcademicSession>> listSessions(String organizationId) => _run(
    'listSessions',
    () async {
      final rows = await _supabase
          .from('academic_sessions')
          .select(AcademicSession.columns)
          .eq('organization_id', organizationId)
          .order('starts_on', ascending: false);
      return rows.map(AcademicSession.fromJson).toList();
    },
    log: (sessions) => {
      'organization_id': organizationId,
      'count': sessions.length,
    },
  );

  Future<AcademicSession> getSession(String sessionId) => _run(
    'getSession',
    () async => AcademicSession.fromJson(
      await _supabase
          .from('academic_sessions')
          .select(AcademicSession.columns)
          .eq('id', sessionId)
          .single(),
    ),
    log: (session) => {'id': session.id, 'terms': session.terms.length},
  );

  /// Saves the changes made to [original] on the details page.
  ///
  /// Not one transaction, so each step keeps the database's rules true on
  /// its own: removed terms go first, the session is widened to hold old and
  /// new term dates, terms are updated (lower sequences first, so numbers
  /// never clash) and added, then the session gets its final name and
  /// dates. A failure part-way leaves a valid calendar; reloading shows it.
  Future<void> saveSession(AcademicSession original, CalendarDraft draft) =>
      _run('saveSession', () async {
        final keptIds = {for (final term in draft.terms) ?term.id};
        for (final term in original.terms) {
          if (!keptIds.contains(term.id)) {
            await _supabase.from('academic_terms').delete().eq('id', term.id);
          }
        }

        final wide = DateTimeRange(
          start: _earlier(original.dates.start, draft.dates.start),
          end: _later(original.dates.end, draft.dates.end),
        );
        if (wide != original.dates) {
          await _updateSession(original.id, {
            'starts_on': _day(wide.start),
            'ends_on': _day(wide.end),
          });
        }

        final savedById = {for (final term in original.terms) term.id: term};
        final ids = <String>[];
        for (var i = 0; i < draft.terms.length; i++) {
          final term = draft.terms[i];
          final values = {
            'name': term.name,
            'sequence': i + 1,
            'starts_on': _day(term.dates.start),
            'ends_on': _day(term.dates.end),
          };
          final saved = term.id == null ? null : savedById[term.id];
          if (saved == null) {
            final row = await _supabase
                .from('academic_terms')
                .insert({
                  ...values,
                  'organization_id': original.organizationId,
                  'session_id': original.id,
                })
                .select('id')
                .single();
            ids.add(row['id'] as String);
            continue;
          }
          ids.add(saved.id);
          if (saved.name != term.name ||
              saved.sequence != i + 1 ||
              saved.dates != term.dates) {
            await _supabase
                .from('academic_terms')
                .update(values)
                .eq('id', saved.id);
          }
        }

        final finalValues = <String, Object>{
          if (draft.name != original.name) 'name': draft.name,
          if (draft.dates != wide) ...{
            'starts_on': _day(draft.dates.start),
            'ends_on': _day(draft.dates.end),
          },
        };
        if (finalValues.isNotEmpty) {
          await _updateSession(original.id, finalValues);
        }

        if (draft.currentTermIndex case final index?) {
          final currentId = ids[index];
          final wasCurrent = original.terms.any(
            (term) => term.id == currentId && term.isCurrent,
          );
          if (!wasCurrent) await _setCurrentTerm(currentId);
        }
      }, log: (_) => {'id': original.id, 'terms': draft.terms.length});

  /// Removes a session and its terms. The database refuses while one of
  /// them is current or anything else uses the session.
  Future<void> deleteSession(AcademicSession session) =>
      _run('deleteSession', () async {
        await _supabase
            .from('academic_terms')
            .delete()
            .eq('session_id', session.id);
        await _supabase.from('academic_sessions').delete().eq('id', session.id);
      }, log: (_) => {'id': session.id});

  /// Seals an ended session: it and everything recorded against it become
  /// read-only. Needs a newer session with a current term.
  Future<void> closeSession(String sessionId) => _run('closeSession', () async {
    await _supabase.rpc('close_session', params: {'p_session_id': sessionId});
  }, log: (_) => {'id': sessionId});

  /// Owner only.
  Future<void> reopenSession(String sessionId) =>
      _run('reopenSession', () async {
        await _supabase.rpc(
          'reopen_session',
          params: {'p_session_id': sessionId},
        );
      }, log: (_) => {'id': sessionId});

  Future<SessionUsage> getUsage(String sessionId) => _run('getUsage', () async {
    final rows = await _supabase.rpc(
      'session_usage',
      params: {'p_session_id': sessionId},
    );
    return SessionUsage.fromJson(
      (rows as List<dynamic>).first as Map<String, dynamic>,
    );
  }, log: (usage) => {'id': sessionId, 'empty': usage.isEmpty});

  Future<void> _updateSession(String id, Map<String, Object> values) async {
    await _supabase.from('academic_sessions').update(values).eq('id', id);
  }

  Future<void> _setCurrentTerm(String termId) async {
    final result = await _supabase.rpc(
      'set_current_term',
      params: {'p_term_id': termId},
    );
    AppLogger.info('Supabase set_current_term result: ${jsonEncode(result)}');
  }

  static DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
  static DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

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

      // Next year's session can be set up before any of its terms starts.
      if (draft.currentTermIndex case final index?) {
        final current = saved.singleWhere(
          (row) => row['sequence'] == index + 1,
        );
        await _setCurrentTerm(current['id'] as String);
      }
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

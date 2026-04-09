import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../database/models/state_realm.dart';
import '../../../database/state_realm_service.dart';
import '../../../models/state_model.dart';

/// Supabase + Realm cache-first conductor for `public.states` (Pattern 1).
class StateService {
  StateService({required StateRealmService stateRealmService})
      : _stateRealmService = stateRealmService;

  final SupabaseClient _supabase = Supabase.instance.client;
  final StateRealmService _stateRealmService;

  /// Realm first; if empty, fetch from Supabase, persist, then return.
  /// On network failure, returns cached Realm rows when available.
  Future<List<StateModel>> fetchStates() async {
    try {
      if (_stateRealmService.hasStatesInRealm()) {
        return _stateRealmService
            .getStatesFromRealm()
            .map(_fromRealm)
            .toList();
      }

      final response = await _supabase
          .from('states')
          .select()
          .order('name', ascending: true);

      final rows = response as List<dynamic>;
      final states = rows
          .map((e) => StateModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (states.isNotEmpty) {
        await _stateRealmService.saveStates(states);
      }

      return states;
    } catch (_) {
      if (_stateRealmService.hasStatesInRealm()) {
        return _stateRealmService
            .getStatesFromRealm()
            .map(_fromRealm)
            .toList();
      }
      rethrow;
    }
  }

  StateModel _fromRealm(StateRealm r) {
    return StateModel(id: r.id, name: r.name);
  }
}

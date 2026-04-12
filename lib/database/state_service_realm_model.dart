/// Barrel: states data layer (Supabase service, Realm cache, models).
///
/// Prefer injecting [StateService] in ViewModels; use this library for one-shot imports.
library;

export 'package:hamrash_admin/api/services/supabase_services/state_service.dart';
export 'package:hamrash_admin/database/models/state_realm.dart';
export 'package:hamrash_admin/database/state_realm_service.dart';
export 'package:hamrash_admin/api/models/supabase_models/state_model.dart';

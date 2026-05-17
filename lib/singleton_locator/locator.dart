import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hamrash_admin/api/api_setup/api_client.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/cloudflare_dio_client.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/image_service.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/secret_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/admin_profile_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/role_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/state_service.dart';
import 'package:hamrash_admin/database/admin_profile_realm_service.dart';
import 'package:hamrash_admin/database/class_realm_service.dart';
import 'package:hamrash_admin/database/realm_service.dart';
import 'package:hamrash_admin/database/role_realm_service.dart';
import 'package:hamrash_admin/database/state_realm_service.dart';
import 'package:hamrash_admin/database/subject_realm_service.dart';
import 'package:hamrash_admin/env_config/flavor_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



/// Global GetIt instance
final GetIt locator = GetIt.instance;

/// Sets up dependency injection
void setupLocator() {
  if (FlavorConfig.instance == null) {
    throw Exception(
      'FlavorConfig must be initialized before setting up locator',
    );
  }

  final env = FlavorConfig.instance!.envConfig();

  // Register APIClient as singleton
  locator.registerLazySingleton<APIClient>(
    () => APIClient(
      BaseOptions(
        baseUrl: env.baseUrl,
        connectTimeout: env.connectTimeout,
        receiveTimeout: env.readTimeout,
      ),
    ),
  );

  // // Register Supabase client as singleton
  locator.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);


  locator.registerLazySingleton<RealmService>(() => RealmService());

  locator.registerLazySingleton<StateRealmService>(
    () => StateRealmService(locator<RealmService>()),
  );

  locator.registerLazySingleton<StateService>(
    () => StateService(stateRealmService: locator<StateRealmService>()),
  );

  locator.registerLazySingleton<RoleRealmService>(
    () => RoleRealmService(locator<RealmService>()),
  );

  locator.registerLazySingleton<RoleService>(
    () => RoleService(roleRealmService: locator<RoleRealmService>()),
  );

  locator.registerLazySingleton<AdminProfileRealmService>(
    () => AdminProfileRealmService(locator<RealmService>()),
  );

  locator.registerLazySingleton<AdminProfileService>(
    () => AdminProfileService(
      adminProfileRealmService: locator<AdminProfileRealmService>(),
    ),
  );

  locator.registerLazySingleton<ClassRealmService>(
    () => ClassRealmService(locator<RealmService>()),
  );

  locator.registerLazySingleton<SubjectRealmService>(
    () => SubjectRealmService(locator<RealmService>()),
  );

  locator.registerLazySingleton<ClassService>(
    () => ClassService(
      classRealmService: locator<ClassRealmService>(),
      subjectRealmService: locator<SubjectRealmService>(),
    ),
  );

  locator.registerLazySingleton<CloudflareDioClient>(
    () => CloudflareDioClient(),
  );

  locator.registerLazySingleton<SecretService>(() => SecretService());

  locator.registerLazySingleton<ImageService>(() => ImageService());

  // // Register Cloudflare services as singletons
  // locator.registerLazySingleton<SecretsService>(() => SecretsService());


}

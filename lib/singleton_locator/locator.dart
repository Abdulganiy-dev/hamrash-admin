import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hamrash_admin/api/api_setup/api_client.dart';
import 'package:hamrash_admin/api/services/supabase_services/organization_member_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/school_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/academic_calendar_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/class_structure_service.dart';
import 'package:hamrash_admin/api/services/supabase_services/subject_service.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/image_service.dart';
import 'package:hamrash_admin/api/services/cloudflare_services/media_upload_service.dart';
import 'package:hamrash_admin/database/realm_service.dart';
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

  // Register Supabase client as singleton
  locator.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  locator.registerLazySingleton<OrganizationMemberService>(
    () => OrganizationMemberService(locator<SupabaseClient>()),
  );

  locator.registerLazySingleton<SchoolService>(
    () => SchoolService(locator<SupabaseClient>()),
  );

  locator.registerLazySingleton<AcademicCalendarService>(
    () => AcademicCalendarService(locator<SupabaseClient>()),
  );

  locator.registerLazySingleton<ClassStructureService>(
    () => ClassStructureService(locator<SupabaseClient>()),
  );

  locator.registerLazySingleton<SubjectService>(
    () => SubjectService(locator<SupabaseClient>()),
  );

  locator.registerLazySingleton<RealmService>(() => RealmService());

  // Uploads go through the `media-upload` edge function, so the app holds no
  // Cloudflare credential.
  locator.registerLazySingleton<MediaUploadService>(
    () => MediaUploadService(locator<SupabaseClient>()),
  );

  locator.registerLazySingleton<ImageService>(() => ImageService());
}

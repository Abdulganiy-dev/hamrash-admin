# Hamrash Admin

Admin app for the Hamrash school management system. Built with Flutter, backed by Supabase, with Clerk for sign-in.

- What the app will do: [ADMIN_FEATURES.md](ADMIN_FEATURES.md)
- Database schema: [docs/supabase-database-schema.md](docs/supabase-database-schema.md)

## Getting started

The Flutter SDK is pinned with [FVM](https://fvm.app) (see `.fvmrc`).

```bash
fvm install
fvm flutter pub get
fvm flutter run --flavor dev -t lib/main_dev.dart
```

Use `--flavor prod -t lib/main.dart` for production builds.

# Hamrash Admin

Admin app for the Hamrash school management system. Built with Flutter, backed by Supabase, with Clerk for sign-in.

- What the app will do: [ADMIN_FEATURES.md](ADMIN_FEATURES.md)
- Database design and guides: [docs/README.md](docs/README.md). Start with [docs/rls-guide.md](docs/rls-guide.md) before writing a migration.
- Migrations and access tests: [supabase/README.md](supabase/README.md)
- Open work: [TODO.md](TODO.md)
- Clerk sign-in setup: [docs/Clerk_Setup_Guide.md](docs/Clerk_Setup_Guide.md)

## Getting started

The Flutter SDK is pinned with [FVM](https://fvm.app) (see `.fvmrc`).

```bash
fvm install
fvm flutter pub get
fvm flutter run --flavor dev -t lib/main_dev.dart
```

Use `--flavor prod -t lib/main.dart` for production builds.

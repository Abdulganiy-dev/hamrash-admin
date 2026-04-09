# Project Folder Structure - Replication Guide

This document explains the **folders under `lib/`** (and a few repo-root folders) in this app so you can recreate the same layout in another Flutter project.

---

## 1. Visual map (`lib/`)

```text
lib/
├── main.dart                    # Prod entrypoint
├── main_dev.dart                # Dev entrypoint
├── firebase_options_*.dart      # Platform Firebase config (if you use Firebase)
│
├── env_config/                  # Dev vs prod (flavor + env values)
├── singleton_locator/           # GetIt registration (DI)
│
├── api/                         # Remote HTTP + typed models + API services
│   ├── api_setup/               # Dio, interceptors, shared API plumbing
│   ├── models/                  # JSON DTOs (by backend: api / supabase / cloudflare)
│   └── services/                # Calls into backends (grouped by provider)
│
├── database/                    # Local persistence (Realm)
│   └── models/                  # Realm object schemas (+ generated *.realm.dart)
│
├── services/                    # App-level services (not tied to one screen)
├── helpers/                     # Small standalone utilities (platform splits, etc.)
├── resources/                   # Theme, colors, logging, shared UI shell, prefs
│   ├── cache/
│   └── utils/
│
├── viewModel/                   # Shared ViewModel base classes
├── views/                       # Screens (feature folders + optional widgets/)
└── widgets/                     # Reusable widgets used across features
```

---

## 2. Folder-by-folder purpose

### `env_config/`

**What it is:** Flavor detection (`dev` / `prod`) and environment-specific values (API base URLs, keys, timeouts, logging flags).

**Replicate:** Add `flavor_config.dart` + `env.dart` (abstract `Env` + `DevEnv` / `ProdEnv`). Wire from `main.dart` / `main_dev.dart` before the rest of the app starts.

---

### `singleton_locator/`

**What it is:** A single place to register dependencies (e.g. GetIt) - API client, Supabase client, Realm services, push, etc.

**Replicate:** One `locator.dart` with `setupLocator()` called **after** flavor/env (and any SDK init that services depend on). Keeps constructors clean and tests easy to override.

---

### `api/`

**What it is:** Everything that talks to **network APIs** in a structured way.

| Subfolder | Purpose |
|-----------|---------|
| **`api_setup/`** | `Dio` / `APIClient`, auth interceptor, logging, response wrappers, JSON helpers. Shared infrastructure, not business endpoints alone. |
| **`models/`** | Data transfer objects. Subfolders group by **source**: `api_models` (your REST API), `supabase_models` (PostgREST shapes), `cloudflare_models` (image/video API responses), etc. Add a subfolder per integration. |
| **`services/`** | Classes that **use** the setup + models to perform operations (`*_service.dart`). Subfolders mirror the backend (`supabase_services`, `cloudflare_services`, ...). |

**Replicate:** Keep "plumbing" in `api_setup`, **immutable-ish models** in `models`, and **orchestration** in `services`. When you add a new backend, add `models/<name>_models/` and `services/<name>_services/` rather than mixing everything in one file.

---

### `database/`

**What it is:** Local database (here: **Realm**) - config, open/close, migrations path, and high-level "repository" style services (`*_realm_service.dart`).

**Replicate:** Put **schema classes** in `database/models/`. Put **read/write coordination** (sync from API, queries) in `database/*_service.dart` at the root of `database/` or in dedicated files. Generated Realm files stay next to models.

---

### `services/`

**What it is:** Cross-cutting app services that are **not** a single REST integration and **not** Realm-specific: navigation helpers, error logging, push notifications, screenshots, secure storage keys, feedback flow glue, image cache, etc.

**Replicate:** If it is used from many features and is not "just UI", it often belongs here instead of inside one `views/` folder.

---

### `helpers/`

**What it is:** Small, focused helpers (e.g. haptics, platform-specific stubs `*_io.dart` / `*_stub.dart`).

**Replicate:** Use for code that would clutter `utils` or `services` - especially **conditional imports** and tiny pure functions.

---

### `resources/`

**What it is:** App-wide presentation and shared non-widget utilities.

| Subfolder / file | Typical contents |
|------------------|------------------|
| Root (`app_theme.dart`, `app_colors.dart`, ...) | `ThemeData`, color tokens, typography, `AppLogger`, `DefaultScaffold`, extensions, error copy |
| **`cache/`** | `SharedPreferences` / local preference wrappers (`user_prefrences.dart` pattern) |
| **`utils/`** | Formatting, validation, device info, navigator key holder, text-field helpers |

**Replicate:** Anything a designer or "design system" would touch lives here; avoid importing `views/` from `resources/`.

---

### `viewModel/`

**What it is:** Base class for screen ViewModels (`BaseViewModel` with busy state, error handling, `notifyListeners`).

**Replicate:** One thin base + optional mixins. Feature-specific ViewModels stay next to their screen under `views/<feature>/`.

---

### `views/`

**What it is:** **Features as screens** - one folder per flow (`home`, `sign_in`, `settings`, ...).

**Conventions in this project:**

- `<feature>.dart` - main `Widget` / route body
- `<feature>_view_model.dart` - state + actions for that screen
- **`widgets/`** - widgets **only used by this feature** (keeps the feature self-contained)

**Replicate:** When a widget is reused in **two or more** features, move it up to `lib/widgets/`.

**Note:** There is a folder named `template.dart/` (with screens inside) - unusual naming; in a new app prefer `template/` or `example_feature/` to avoid confusion with a `.dart` file.

---

### `widgets/`

**What it is:** Shared UI components: buttons, text fields, modals, listeners, list items, etc.

**Replicate:** If multiple `views/*` import it, it belongs here.

---

## 3. How the layers fit together

```text
views (UI)  →  viewModel (state)  →  services / api / database
                     ↓
              singleton_locator + env_config
```

- **Screens** in `views/` should stay thin; logic goes in `*_view_model.dart` or injected services.
- **Network** goes through `api/`; **local cache** through `database/`; **glue** in `services/`.

---

## 4. Repo root (optional but useful to copy)

| Path | Purpose |
|------|---------|
| **`docs/`** | Guides like this one, architecture notes |
| **`supabase/`** | SQL migrations / Supabase CLI assets (if you use Supabase) |
| **`test/`** | Unit / widget tests mirroring `lib/` where possible |

Platform folders (`android/`, `ios/`, ...) are standard Flutter; flavor setup is documented separately in `LLM_Dev_Prod_Environment_Setup_Guide.md`.

---

## 5. Minimal replication order

1. Create **`env_config/`** + **`singleton_locator/`** and call them from **`main.dart`**.
2. Add **`resources/`** (theme + logger + one `DefaultScaffold` if you use it).
3. Add **`viewModel/base_view_model.dart`**.
4. For each feature: **`views/<feature>/`** with screen + view model + local **`widgets/`**.
5. When you add HTTP: **`api/api_setup/`** then **`api/models/`** + **`api/services/`**.
6. When you add local DB: **`database/`** with **`models/`** + services.
7. Promote cross-feature code to **`widgets/`**, **`services/`**, or **`helpers/`** as it grows.

---

*This matches the **artisan_passport** `lib/` tree. Rename packages and drop folders you do not need (e.g. `supabase_models` if you have no Supabase).*

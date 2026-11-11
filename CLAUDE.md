# Hamrash Admin: working rules

Flutter app for school staff (iOS and Android only). Backend: Supabase (project `ccvyhbyrtobdsecqvhcr`) and Clerk. Designs live in Paper (file "Hamrash", page "Hmarash Admin"; the "Design System" page is the visual source of truth).

## Commands
- Always use `fvm flutter ...` (the default `flutter` on PATH is too old; `.fvmrc` pins 3.44.8).
- One check: `tool/check.sh` (analyze, tests, handbook). Pass a test path to run only that: `tool/check.sh test/views/team`. Run the whole suite once at the end of a feature, not after every edit.

## Hard rules
- **Never commit, branch or push** unless asked. When asked, no `Co-Authored-By`/Claude attribution.
- **Never write to the database.** No `apply_migration`, no `execute_sql` writes, no `supabase db push`, no inserts into the migration history. Read-only SELECTs and `EXPLAIN` are fine for inspecting the live schema. Every database change is written as a migration file in `supabase/migrations/` (next number, same header/comment style as recent ones, with its access test in `supabase/tests/`, handbook entries and `docs/people-schema.md`-style docs updated). The user reviews the SQL and applies it themselves; only then bump `meta.migrationsLive`.
- **Who handles a database change:**
  - Small (a nullable column, a column grant, one index, a small tweak to an existing function): Sonnet 5.5 at high effort writes the migration, the test and the docs.
  - Big (new table or RPC, RLS or policy changes, anything touching auth/roles, pagination/search functions, data backfills): ask the user which agent should handle it before starting, then hand it the migration-file-only rules above.
  - Either way, say plainly in the report that nothing was applied.
- Mobile only. Light mode only. Nunito only (via `AppText`/`AppTypography`). They/them for any person in copy.
- Every migration or data-access change also updates `docs/handbook/data.js` (and `snippets.js` via the repo tooling); `python3 docs/handbook/check.py` must pass. `meta.migrationsLive` only after the user has applied it.

## Architecture
Service → ViewModel → View. No repositories. Services in `lib/api/services/supabase_services/` (constructor-injected `SupabaseClient`, registered in `lib/singleton_locator/locator.dart`, use `runRefusable` so Postgres refusals become readable `SupabaseRefusal`s). View models extend `BaseViewModel` and take services as optional params defaulting to `locator<...>()`. Screens use `ViewModelBuilder<T>.reactive` inside `DefaultScaffold`. Navigation only through `NavigationService`; a screen pops `true` when it changed something. Models in `lib/api/models/<feature>/`. Feature code in `lib/views/<feature>/` with a `widgets/` folder; promote a widget to `lib/core/widgets/` only when two features use it.

## UI conventions (match the Design System; don't invent)
- Tokens, never literals: `AppPalette`, `LightColors`, `AppSpacing`, `AppRadius`, `AppTypography`. Icons: Lucide via `AppIcons`/`AppIcon`.
- Layout: 16px side gutters; app bar slot always reserved; keyboard floats over content (`AppKeyboardBar`); pinned bottom bars go in `DefaultScaffold.bottomNavigationBar` and are full width with centred content.
- **Two stacked buttons (any kind, incl. text links) are 16px apart** (visible gap).
- Tappable custom surfaces use `BouncyButton` (spring press + haptic), not a bare `GestureDetector`.
- Buttons: page CTAs are flat (aubergine fill); gradients only on buttons inside sheets and alerts. Chips are flat tinted (no gradient, no check mark, no animation).
- A title over a card is `AppSectionCard` (or `AppSection` for non-card content), never `AppSectionHeader` + a hand-written `SizedBox`: the gap is built in (12 without an action, 0 with an `AppSectionAction`).
- Dividers inside cards/lists/sheets: `AppDivider` (faint colour, inset 16; staff list rows start at the text column). Card outer border stays `AppPalette.stone200`.
- Icon + label groups use `AppIconLabel` (fixed icon slot, same optical alignment as the sign-in buttons).
- Dates: `AppDateFormat`; Nigerian phones shown nationally (`PhoneFormat`), stored as saved.
- Don't add animations that weren't asked for.

## Working with Paper
- Artboards are named `8.4 · Staff detail · Not on app` etc. Read exact values with the Paper tools (`get_screenshot`, `get_jsx`, `get_computed_styles`); never read sizes from screenshots, never show raw node ids to the user.
- After changing a page that appears dimmed behind a sheet artboard, resync those backdrops.
- Mobbin research only when the user asks; otherwise the Design System decides.

## How to work efficiently
- Small fixes (a label, an alignment, one icon): just do them, no agents, no Paper step.
- A UI change with layout: one implementation agent that reads the Paper artboard itself; the brief names the artboards and files, not the whole spec.
- New screen/flow: design in Paper first, then one implementation agent.
- Verify once: `tool/check.sh` on the touched folder; screenshots only for what changed.
- Keep briefs short: link to this file for the standing rules.

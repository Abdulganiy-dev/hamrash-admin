# Clerk setup guide

How to set up Clerk sign-in for an app made from this template, with Supabase trusting Clerk's tokens. Do this once per project. Repeat step 2 for every app if the project has more than one (for example a customer app and a partner app).

The examples use this app's IDs (`com.everydayworks.hamrash.admin`, with dev builds adding `.dev`).

---

## 1. Create the Clerk application

- Create one application in the [Clerk dashboard](https://dashboard.clerk.com). It starts with a **Development** instance. Add a **Production** instance before the first release.
- If a project has several apps on the same database, they share these two instances. That way one person has one Clerk user ID across every app and platform.

## 2. Native applications page

Open **Native applications** in each instance (dev and prod).

**Enable Native API.** Turn it on in both instances and leave it on. `clerk_flutter` talks to Clerk as a native app, so sign-in fails without it.

**iOS tab** (add each app):

| Field | Value |
|---|---|
| App ID Prefix | Your Apple Team ID. It's `DEVELOPMENT_TEAM` in `ios/Runner.xcodeproj/project.pbxproj`, or under developer.apple.com → Membership details |
| Bundle ID | `com.everydayworks.hamrash.admin.dev` in the dev instance, `com.everydayworks.hamrash.admin` in prod |

**Android tab** (add each app):

| Field | Value |
|---|---|
| Namespace | `android_app` (Clerk's default; not the `namespace` in `build.gradle.kts`) |
| Package name | `com.everydayworks.hamrash.admin.dev` in dev, `com.everydayworks.hamrash.admin` in prod |
| SHA-256 fingerprints | Dev: the debug key of every machine you build on. Prod: the release key's, or Play App Signing's from Play Console → App integrity |

Get the debug fingerprint:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA256
```

**Allowlist for mobile SSO redirect.** Only needed for Google or Apple sign-in through the browser. Add `com.everydayworks.hamrash.admin.dev://callback` in dev and `com.everydayworks.hamrash.admin://callback` in prod. The app must also handle that link (step 5).

Registering apps is **optional in dev but required in prod**. Production instances check that sign-in returns to a registered bundle ID or package name, so add them before the first release build.

## 3. Connect Clerk to Supabase

1. In Clerk, enable the **Supabase** integration and copy your Clerk domain.
2. In Supabase, go to **Authentication → Sign In / Up → Third-Party Auth → Add provider → Clerk** and paste the domain.

Database conventions:
- Tables keep `uuid` primary keys and add a `clerk_id text` column for the user.
- Clerk user IDs are strings like `user_38hp…`, not UUIDs.
- RLS compares `clerk_id = (auth.jwt() ->> 'sub')`. Never use `auth.uid()`; it can't read a Clerk ID. See [`RLS_Approach_Guide.md`](RLS_Approach_Guide.md).

## 4. Publishable keys

- In the Clerk dashboard, open **Configure → API keys** with the right instance selected.
- Put the **Publishable key** in `clerkPublishableKey` in `lib/env_config/env.dart`: `pk_test_…` in the dev getter, `pk_live_…` in the prod getter.
- Publishable keys are safe in the app. The **secret key** (`sk_…`) must never go in the app or in source control.

## 5. App code

Already wired in the template:
- **Packages:** `clerk_flutter`, `clerk_auth` and `app_links` in `pubspec.yaml`.
- **`lib/app.dart`:** wraps the app in `ClerkAuth(config: ClerkAuthConfig(publishableKey: …))`. This only happens once a key is set (`env.hasClerk`).
- **`lib/main.dart` and `lib/main_dev.dart`:** give Supabase Clerk's session token through `accessToken: … ClerkAuth.of(context).sessionToken()`, so Supabase requests carry the Clerk user.

Not yet in the template; add these when you need browser-based Google or Apple sign-in:
- **iOS:** add the `<bundle id>` URL scheme to `CFBundleURLTypes` in `ios/Runner/Info.plist`, one per flavor.
- **Android:** add an intent filter for `<package name>://callback` to `android/app/src/main/AndroidManifest.xml`.
- **Clerk:** pass a `redirectionGenerator` and `deepLinkStream` (from `app_links`) to `ClerkAuth`, following the [clerk_flutter example](https://pub.dev/packages/clerk_flutter/example). Alternatively, use the SDK's in-app WebView option, which skips the redirect and the allowlist.

## Checklist

- [ ] Clerk app created; dev instance in use, prod instance added before release
- [ ] Native API enabled in both instances
- [ ] iOS and Android apps registered (required in prod)
- [ ] SSO redirect allowlisted and handled in the app (only for browser OAuth)
- [ ] Clerk added as a third-party auth provider in Supabase
- [ ] `pk_test_` / `pk_live_` keys in `env.dart`

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
- Clerk user IDs are strings like `user_38hp…`, not UUIDs.
- The caller's Clerk ID is `auth.jwt() ->> 'sub'`. Never use `auth.uid()`; it can't read a Clerk ID.
- School tables don't store a Clerk ID. It lives only on `organization_members.clerk_user_id`, and the access rules reach it through the helper functions. See [`rls-guide.md`](rls-guide.md).

## 4. Publishable keys

- In the Clerk dashboard, open **Configure → API keys** with the right instance selected.
- Put the **Publishable key** in `clerkPublishableKey` in `lib/env_config/env.dart`: `pk_test_…` in the dev getter, `pk_live_…` in the prod getter.
- Publishable keys are safe in the app. The **secret key** (`sk_…`) must never go in the app or in source control.

## 5. App code

Wired in the app:
- **Packages:** `clerk_flutter`, `clerk_auth`, `flutter_web_auth_2` and `package_info_plus` in `pubspec.yaml`.
- **`lib/app.dart`:** wraps the app in `ClerkAuth` and routes signed-out users to sign-in. After sign-in it checks for an `organization_members` row with that Clerk user ID: existing members enter the current main-app template, and other users see the Join screen.
- **`lib/views/onboarding/sign_in/sign_in_view_model.dart`:** starts Apple or Google OAuth in Clerk and completes the browser callback.
- **`lib/main.dart` and `lib/main_dev.dart`:** pass Clerk's session JWT to Supabase through `accessToken`, so Supabase RLS sees the Clerk user.
- **iOS:** `ios/Runner/Info.plist` registers the bundle ID as the OAuth callback scheme; Xcode substitutes the active flavor's bundle ID.
- **Android:** `android/app/src/main/AndroidManifest.xml` registers the application ID as the OAuth callback scheme; Gradle substitutes the active flavor's application ID.

The Clerk dashboard still needs the OAuth redirect allowlist entries from step 2, and the Google and Apple providers must be enabled in Clerk.

## Checklist

- [ ] Clerk app created; dev instance in use, prod instance added before release
- [ ] Native API enabled in both instances
- [ ] iOS and Android apps registered (required in prod)
- [ ] SSO redirect allowlisted and handled in the app (only for browser OAuth)
- [ ] Clerk added as a third-party auth provider in Supabase
- [ ] `pk_test_` / `pk_live_` keys in `env.dart`

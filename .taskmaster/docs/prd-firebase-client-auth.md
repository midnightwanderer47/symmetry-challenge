# Product Requirements Document: Firebase Client Authentication (Symmetry News App)

## Purpose

The main PRD ([prd.md](./prd.md)) requires **Firestore** and **Storage** security rules that only allow writes when `request.auth != null`. Those rules are necessary but not sufficient: the Flutter app must establish an **authenticated Firebase session** before uploads. This document adds an explicit product requirement for that client-side authentication, which was not spelled out as a separate deliverable in the original PRD.

## Problem Statement

Without integrating the Firebase Auth SDK and performing at least one successful sign-in, every write to Firestore or Storage is evaluated as unauthenticated and fails with `permission-denied`, regardless of correct rules deployment.

## Goals

1. Ensure every user session that performs article upload or thumbnail upload has a valid Firebase Auth user (`FirebaseAuth.instance.currentUser != null`).
2. Keep the implementation aligned with existing backend rules in `starter-project/backend/firestore.rules` and `storage.rules`.
3. Prefer minimal UX friction for the assignment (e.g. **Anonymous** sign-in at app startup), unless a different method is explicitly chosen later.

## Non-goals

- Custom backend / JWT outside Firebase (out of scope).
- Full account management UI (email verification, password reset flows) unless explicitly added later.
- Replacing or weakening security rules to allow unauthenticated writes.

## Functional Requirements

### FR1 — Dependency

- Add **`firebase_auth`** to the Flutter app `pubspec.yaml`, compatible with the existing Firebase BOM / `firebase_core` version.

### FR2 — Firebase Console

- In Firebase Console → **Authentication** → **Sign-in method**, enable at least one provider required by the implementation:
  - **Anonymous** (recommended default for development and fastest path to `request.auth != null`), and/or
  - Other providers (Google, Email/Password) if product requires named users.

### FR3 — Application bootstrap

- After `Firebase.initializeApp(...)` in `main.dart` (or an equivalent app initialization module), ensure the user is signed in:
  - If `currentUser == null`, invoke sign-in (e.g. `signInAnonymously()`).
  - Handle failures visibly in debug or via logging so misconfiguration (provider disabled) is diagnosable.

### FR4 — Compatibility with upload flow

- Article upload and thumbnail upload must only run after auth is ready (same isolate; typically satisfied if sign-in completes before `runApp` or before navigable upload routes).
- No changes to Clean Architecture layering beyond what is necessary (auth may live in `main.dart` or a small `core`/`data` helper; domain remains free of Firebase if possible).

### FR5 — Payload vs rules (related)

- Existing rules require non-empty `thumbnailURL` on Firestore writes. Client behavior must either:
  - Require a thumbnail before submit, or
  - Supply a non-empty placeholder URL when no image is selected,
  so writes are not rejected for missing `thumbnailURL` after auth is fixed.

## Acceptance Criteria

- [ ] `firebase_auth` is listed in `pubspec.yaml` and the app builds for target platforms.
- [ ] At least one sign-in method is enabled in the Firebase project matching the app configuration.
- [ ] After cold start, `FirebaseAuth.instance.currentUser` is non-null before the user can complete an upload (verify with logs or debugger).
- [ ] Firestore `articles` create and Storage `media/articles/` upload succeed against deployed rules when rules require `request.auth != null`.
- [ ] Documentation: one short paragraph in `docs/REPORT.md` (or README) stating that anonymous (or chosen) auth is used so security rules are satisfied.

## Verification

1. Deploy `firestore.rules` and `storage.rules` to the same project as `firebase_options.dart`.
2. Run the app, trigger upload with valid form + thumbnail → success path.
3. Optional: temporarily disable Anonymous in console → confirm sign-in error surfaces, proving the app depends on Auth.

## Relation to Taskmaster

- Parse this PRD with Taskmaster **append** to add tasks without removing existing ones:

  ```bash
  task-master parse-prd .taskmaster/docs/prd-firebase-client-auth.md --append
  ```

- Alternatively add a single high-level task manually: “Integrate Firebase Auth (anonymous sign-in at startup) and satisfy thumbnailURL for Firestore rules.”

## References

- [prd.md](./prd.md) — Task 1.3 (security rules), Task 2.0 (Firebase setup), verification checklist (unauthenticated writes blocked).
- [starter-project/backend/firestore.rules](../starter-project/backend/firestore.rules)
- [starter-project/backend/storage.rules](../starter-project/backend/storage.rules)

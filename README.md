# Report: Symmetry Challenge — News App

## 1. Introduction

Coming into this project, I was comfortable with React Native and JavaScript/TypeScript but had never worked with Flutter or Dart. The challenge was exciting — a scoped, real-world feature (journalist article upload) with clear architecture requirements and room to overdeliver.

---

## 2. Learning Journey

**Already knew:** React Native, JavaScript/TypeScript, Clean Architecture concepts, REST APIs.

**Learned during this project:**

- **Flutter & Dart** — widget tree, Dart null-safety, async patterns, and project structure from scratch.
- **Firebase Firestore & Storage** — schema design, security rules, real-time queries, image upload flows.
- **Flutter BLoC / Cubits** — distinguishing when to use BLoC (event-driven) vs Cubit (simpler state), and how to compose them with use cases.
- **Floor ORM** — SQLite persistence in Flutter with migrations.
- **Retrofit for Flutter** — type-safe HTTP client generation.

Main resources used: Flutter docs, Firebase docs, BLoC library docs, pub.dev package READMEs, and existing project architecture docs.

---

## 3. Challenges Faced

**1. Merging two data sources into one feed**
The home feed needed to combine Firestore user articles and the News API. The tricky part was deduplication and handling partial failures (e.g., News API down). Solved by normalizing titles for comparison and treating each source independently — partial results still render.

**2. Firebase Storage + Firestore atomicity**
Uploading a thumbnail then saving the article URL required coordinated async steps without a transaction. Solved with a two-phase upload in `ArticleUploadCubit`: upload image → get URL → save article, with a timeout guard.

**3. Clean Architecture with Firebase**
Firebase's SDK is inherently data-layer code, but it was tempting to leak it into business logic. Strict adherence to the repository pattern and interface abstractions kept this clean.

**4. Database migration**
Adding `firestoreId` and `userId` to the local SQLite schema mid-development required writing a Floor migration. Small but easy to miss.

---

## 4. Reflection and Future Directions

**Technically:** Working within Clean Architecture's constraints forced better design decisions. BLoC/Cubits shine when the UI needs to react to multiple async states simultaneously.

**Professionally:** Shipping a feature end-to-end — schema → rules → backend → domain → data → presentation → tests — in one cycle was good practice for thinking holistically.

**Future improvements:**

- Replace anonymous auth with proper sign-in (Google/email) for article ownership.
- Add offline-first support by syncing Firestore to the local Floor database.
- Extract the `ArticleRepositoryImpl` merge logic into a dedicated `FeedAggregator` service — it's doing too much.
- Add CI/CD with GitHub Actions to run tests on PR.

---

## 5. Proof of the Project

> Screenshots and screen recordings are available upon request or can be found in the `/docs/assets/` folder if added.

Key flows to demonstrate:

- Home feed loading merged articles
- Upload article with thumbnail
- Article detail with markdown rendering
- Search with debounced results
- My Articles screen with delete confirmation
- Edit article flow
- Infinite-scroll load-more on home feed
- Dark/light theme toggle via Settings sheet

---

## 6. Overdelivery

### New Features Implemented

| Feature                  | Description                                                                                     |
| ------------------------ | ----------------------------------------------------------------------------------------------- |
| **Merged Feed**          | Home screen combines Firestore user articles + News API articles in one list, sorted by date    |
| **Debounced Search**     | Search queries both sources with a 300ms debounce; no redundant API calls                       |
| **Markdown Rendering**   | Article content renders as formatted markdown via `flutter_markdown`                            |
| **Theme Persistence**    | Dark/light mode toggled from a Settings bottom sheet; preference saved via `shared_preferences` |
| **Image Caching**        | Thumbnails cached with `cached_network_image` to avoid redundant network requests               |
| **Delete Confirmation**  | Custom `DeleteArticleDialog` prevents accidental deletions                                      |
| **Firestore Pagination** | Cursor-based paging for user articles; home feed supports infinite-scroll load-more             |
| **Article Editing**      | Authors can update their own articles post-publish via `EditArticleCubit` + Firestore `update`  |
| **Markdown Editor**      | `MarkdownEditorWidget` replaces plain text field on both upload and edit screens                |
| **Test Suite**           | 9 test files covering unit, widget, cubit, and integration tests                                |

### Prototypes Created

**Firebase Security Rules** (`backend/firestore.rules`, `backend/storage.rules`):

- Enforces required fields on write (title, content, author, thumbnailURL)
- Restricts deletes to the article's owner (`userId` match)
- Storage write limited to authenticated users, 10 MB max, image types only

**DB Schema** (`backend/docs/DB_SCHEMA.md`):

- Documented Firestore collection schema with field types, constraints, and index definitions

### How Could This Be Further Improved

- **Optimistic UI** — Show article immediately on upload before Firestore confirms
- **Notifications** — Firebase Cloud Messaging for new article alerts

---

## 7. Architecture Overview

The project strictly follows Clean Architecture with three layers per feature:

```
features/daily_news/
├── data/         # External world (Firestore, Storage, News API, SQLite)
├── domain/       # Business logic (entities, use cases, repository interfaces)
└── presentation/ # UI (BLoC/Cubits, pages, widgets)
```

**9 use cases** cover the full CRUD surface: upload, get, search, save, remove, delete, get user articles, upload thumbnail, and get single article.

**GetIt** is used for dependency injection — all dependencies are registered at app startup in `injection_container.dart`.

---

## 8. Running the app (iOS and Android simulators)

This section explains how to run the Flutter frontend on **iOS Simulator** and **Android Emulator** from a clone of this repository. It follows the same spirit as [Extra Sections](docs/REPORT_INSTRUCTIONS.md) in the report instructions.

### Prerequisites

- **Flutter** installed and on your `PATH` (`flutter doctor` should show Xcode / Android toolchain as configured for the platforms you use).
- **Firebase client config** generated locally (these files are not committed; see [`frontend/README.md`](frontend/README.md)):
  - `frontend/lib/firebase_options.dart`
  - `frontend/android/app/google-services.json`
  - `frontend/ios/Runner/GoogleService-Info.plist`
- From the repo root, install dependencies: `just get` (runs `flutter pub get` in `frontend/`).

### iOS Simulator (macOS only)

1. Install **Xcode** from the App Store and accept the license; open Xcode once so components finish installing.
2. Start a simulator: **Xcode → Open Developer Tool → Simulator**, or run `open -a Simulator`.
3. From the **repository root**, list devices and confirm an iOS simulator appears:

   ```bash
   cd frontend && flutter devices
   ```

4. Run the app on the booted simulator (from repo root):

   ```bash
   just run -d ios
   ```

   If you have multiple iOS devices listed, pass a specific device id: `just run -d <device_id>` (use the id from `flutter devices`).

### Android Emulator

1. Install **Android Studio** and, via **SDK Manager**, install an Android SDK and at least one **system image** (e.g. Pixel API 34).
2. Create and start a virtual device: **Android Studio → Device Manager →** create/start an AVD, or from a terminal:

   ```bash
   flutter emulators
   flutter emulators --launch <emulator_id>
   ```

3. From the **repository root**, run:

   ```bash
   just run -d android
   ```

   Or target a specific device: `just run -d <device_id>` after `flutter devices`.

### Troubleshooting

- **`flutter doctor`** — fix any red items (licenses: `flutter doctor --android-licenses`).
- **No devices** — boot the simulator or emulator *before* `flutter run`; only one command is needed if exactly one device is online.
- **Firebase errors at startup** — ensure the three Firebase files above exist and match your Firebase project (`flutterfire configure` from `frontend/`).

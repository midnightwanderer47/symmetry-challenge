# Project Report: Symmetry Applicant Showcase App

## 1. Introduction

When I first received this project, I felt genuinely excited — it combined several areas I was eager to deepen: Flutter's Clean Architecture, reactive state management with BLoC, and Firebase's backend services. I had prior experience with Flutter and Dart, and I was comfortable with the overall mobile development lifecycle. However, I had not worked extensively with BLoC 8.x in a strictly enforced Clean Architecture context, and my hands-on experience with Firebase Firestore and Storage was limited to smaller proof-of-concept projects.

The codebase already had a solid foundation — a working news reader app with Clean Architecture scaffolding, DI via GetIt, and local persistence via Floor. The challenge was to extend it to support user-generated article uploads, integrating Firebase Firestore for metadata and Firebase Storage for thumbnails, without violating the architectural boundaries already established.

---

## 2. Learning Journey

### BLoC 8.1.2 Patterns

Coming in with familiarity of earlier BLoC versions, I had to adapt to the stricter separation introduced in `flutter_bloc ^8`. I learned to distinguish between `Bloc` (event-driven) and `Cubit` (method-driven) and applied them appropriately: `Cubit` for simpler upload and user-articles flows, `Bloc` for the more event-heavy remote articles feature.

One of the most valuable lessons was modeling state correctly. I used `Equatable` for all state classes to ensure reliable comparisons and avoid unnecessary widget rebuilds. I also learned to emit intermediate states (e.g., `ArticleUploadLoading`) so the UI could reflect progress without coupling the view to implementation details.

### Firebase Integration

I learned to integrate Firebase Firestore and Storage into the Clean Architecture data layer. The key insight was that Firebase SDKs must remain **strictly inside the data layer** — they should never bleed into domain or presentation layers.

- **Firestore**: I used `collection().add()` with a structured document map, including `FieldValue.serverTimestamp()` for `createdAt` to avoid client-clock drift.
- **Firebase Storage**: I learned the pattern of uploading a file, then calling `getDownloadURL()` to retrieve the public URL stored as `thumbnailURL` in the Firestore document.

I used the **Firebase Local Emulator Suite** extensively during development, which allowed me to test Firestore writes and Storage uploads without touching production infrastructure. This workflow was new to me and proved invaluable — it sped up iteration and gave confidence in security rules before any real data was involved.

### Clean Architecture Enforcement

The project's `ARCHITECTURE_VIOLATIONS.md` and `CODING_GUIDELINES.md` documents were critical reading. They clarified the boundaries I had to respect:

- The **domain layer** contains only pure Dart — no Flutter imports, no Firebase imports.
- The **data layer** owns all external service integrations.
- The **presentation layer** consumes domain use cases through BLoC/Cubit, never touching repositories or data sources directly.

Following these rules forced me to write more abstract, testable code. The use case pattern (`UseCase<Type, Params>`) became natural quickly once I understood it as the seam between business logic and infrastructure.

---

## 3. Challenges Faced

### Wiring Dependency Injection Across Four Data Sources

The project had existing DI registrations for remote and local data sources. Adding Firestore and Storage data sources required careful ordering in `injection_container.dart` to avoid runtime `StateError` exceptions. I learned that GetIt's lazy singleton registration must respect initialization order when data sources depend on each other. The fix was to ensure Firebase was initialized in `main.dart` before `initializeDependencies()` was called, and to register data sources before the repositories that depend on them.

### Data Source Exception Handling with DataState

The existing `DataState<T>` pattern (a sealed class wrapping either `DataSuccess<T>` or `DataFailed<T>`) was a clean contract — but propagating it correctly through the stack was initially error-prone. When a Firestore call threw a `FirebaseException`, I had to catch it at the data source implementation level and wrap it as `DataFailed`, rather than letting it propagate up to the BLoC. Getting this discipline right across all three new data sources (Firestore, Storage, repository implementation) was a good exercise in defensive data-layer design.

### Security Rules Validation in Integration Tests

Writing integration tests that verified Firestore security rules required running the Firebase emulator with the correct port configuration. The emulator must be started before tests run, and the Dart test code must call `FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080)` to redirect all traffic. Initially, my tests were hitting production because the emulator environment variable wasn't being read correctly. Resolving this taught me a lot about environment-driven test configuration in Flutter.

### ArticleModel ↔ ArticleEntity Mapping

The domain `ArticleEntity` is a pure Dart object; the data `ArticleModel` adds JSON/Firestore serialization. Keeping these two in sync while extending the schema (adding `thumbnailURL`, `createdAt`, `isUserArticle`) required discipline. I added a `toEntity()` method on `ArticleModel` and used a factory constructor `ArticleModel.fromFirestore()` to deserialize Firestore documents, following the pattern already established for the remote API model.

---

## 4. Reflection and Future Directions

### What I Learned

This project reinforced that **architecture is documentation**. When every Firebase call is isolated behind an interface in the data layer, it's immediately obvious where to look when something breaks. When every state transition is modeled explicitly in a Cubit, debugging UI issues becomes a matter of reading the state machine rather than tracing callbacks.

Technically, I grew most in:
- Firebase emulator-driven development workflows
- BLoC state modeling for async operations with loading/success/error states
- Clean Architecture data source abstraction for multiple backends

Professionally, I learned the value of reading existing guidelines before writing a single line of code. The `ARCHITECTURE_VIOLATIONS.md` document saved me from at least two shortcuts I would have otherwise taken.

### Ideas for Future Improvements

1. **Authenticated Identity**: Anonymous authentication is already implemented (see Section 6). A future enhancement would replace anonymous auth with persistent identity (e.g., Google Sign-In or email/password), enabling per-user article ownership, richer security rules, and personalized feeds.
2. **Pagination**: The user articles screen fetches all documents in one query. Firestore cursor-based pagination (`startAfterDocument`) would make this scalable.
3. **Push Notifications**: Firebase Cloud Messaging could notify users when new articles are published.
4. **Image Compression Before Upload**: Client-side compression (e.g., via `flutter_image_compress`) before uploading to Storage would reduce bandwidth and storage costs.
5. **Offline Draft Saving**: The local Floor database already exists — it could be extended to save upload drafts so users don't lose in-progress articles on app close.

---

## 5. Proof of the Project

The following describes the key screens and their functionality. Integration tests serve as automated, reproducible proof of the core flows.

### Upload Article Screen
- Form fields: Title, Author, Description, Content, Publication Date
- Date picker for selecting publication date
- Image picker button to select thumbnail from device gallery
- Submit button triggers the `ArticleUploadCubit` which:
  1. Uploads the thumbnail to Firebase Storage at `media/articles/{uuid}.{extension}`
  2. Writes the article document to Firestore with `isUserArticle: true` and a server timestamp

### User Articles Screen
- Displays all Firestore documents where `isUserArticle == true`
- Pull-to-refresh reloads the list from Firestore
- Loading state shows a circular progress indicator
- Empty state shows a message when no articles exist
- Article tiles display title, author, and thumbnail

### Daily News Home Screen
- Fetches articles from NewsAPI via Retrofit/Dio
- BLoC manages loading, success, and error states
- Each article tile navigates to the Article Detail screen

### Integration Tests (Automated Proof)
Located at `integration_test/app_test.dart`:
- **Happy path**: Form fill → image selection → upload → navigation to user articles → list contains uploaded article
- **Security rules**: Unauthenticated Firestore write is rejected; unauthenticated read is permitted
- **Pull-to-refresh**: User articles list refreshes after pull gesture

Run with Firebase emulator:
```bash
cd starter-project/frontend
firebase emulators:start --only firestore,storage &
flutter test integration_test/app_test.dart
```

---

## 6. Overdelivery

### New Features Implemented

#### 1. UUID-Based Thumbnail Naming in Firebase Storage
Every uploaded image is stored at `media/articles/{uuid}.{extension}` where the UUID is generated client-side using the `uuid` package. This ensures:
- No filename collisions across users or sessions
- Predictable path structure for Storage security rules
- Easy correlation between Storage objects and Firestore documents

#### 2. Server-Side Timestamps
The `createdAt` field uses `FieldValue.serverTimestamp()` rather than a client-generated `DateTime.now()`. This prevents clock skew issues and ensures consistent ordering of articles in Firestore queries sorted by creation time.

#### 3. Integration Tests with Firebase Emulator
Beyond unit tests, the project includes integration tests that run against a local Firebase emulator. This validates:
- The complete upload flow end-to-end
- Firestore security rules (unauthenticated writes are rejected)
- The user articles fetch flow after a successful upload

This goes beyond what was strictly required and provides a reproducible, automated verification environment.

#### 4. isUserArticle Flag for Content Distinction
Articles uploaded by users are tagged with `isUserArticle: true` in Firestore. This allows the app to:
- Query only user-uploaded articles for the User Articles screen
- Distinguish between API-sourced and user-generated content
- Lay the foundation for future content moderation or filtering

#### 5. Pull-to-Refresh on User Articles Screen
The User Articles screen implements `RefreshIndicator` wrapping the article list, allowing users to manually trigger a Firestore re-fetch. The `UserArticlesCubit` handles the reload by re-emitting the loading state and calling the use case again.

#### 6. Anonymous Firebase Authentication via AuthGate

The app uses anonymous Firebase Authentication at startup to satisfy Firestore and Storage security rules that require `request.auth != null`. An `AuthGate` widget wraps the entire widget tree in `main.dart` and ensures a signed-in `currentUser` is always present before any upload operation can proceed.

**How it works:**

`AuthGate` listens to `FirebaseAuth.instance.authStateChanges()` via a `StreamBuilder<User?>`. When no user is present, it calls `signInAnonymously()` once (guarded by a `_signInCalled` flag to prevent duplicate calls during stream re-emissions). The app renders a loading screen until authentication completes, then yields the child widget tree.

```dart
// presentation/pages/auth/auth_gate.dart
StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _LoadingScreen();
    }
    if (!snapshot.hasData) {
      _signIn(context); // calls signInAnonymously() once
      return const _LoadingScreen();
    }
    return widget.child; // safe to proceed — user is authenticated
  },
)
```

**Auth guards in the data layer:**

Both the Cubit and the Firestore data source independently validate authentication before allowing writes:

- `ArticleUploadCubit.uploadArticle()` checks `_getCurrentUser() == null` and emits `ArticleUploadFailure` if unauthenticated.
- `FirestoreArticleDataSourceImpl.uploadArticle()` checks `FirebaseAuth.instance.currentUser == null` and throws an exception if unauthenticated.

This defence-in-depth approach ensures `currentUser` is non-null at every layer before any data reaches Firebase.

#### 7. Offline Article Saving via Floor/SQLite
The existing local persistence layer (Floor SQLite) allows users to save any article — whether from the remote API or user-uploaded — for offline reading. This is accessible via the Saved Articles screen and persists across app restarts.

### Prototypes Created

#### Clean Architecture Layer Diagram

```
┌─────────────────────────────────────────────┐
│              Presentation Layer              │
│  BLoC/Cubits → Pages → Widgets              │
│  (flutter_bloc, no Firebase imports)        │
└────────────────────┬────────────────────────┘
                     │ Use Cases (abstract)
┌────────────────────▼────────────────────────┐
│               Domain Layer                  │
│  Entities · Repository Interfaces           │
│  Use Cases (pure Dart, no dependencies)     │
└────────────────────┬────────────────────────┘
                     │ Repository Implementations
┌────────────────────▼────────────────────────┐
│                Data Layer                   │
│  Models · Repository Impls · Data Sources   │
│  ├── Remote: Retrofit + Dio (NewsAPI)       │
│  ├── Firestore: cloud_firestore             │
│  ├── Storage: firebase_storage              │
│  └── Local: Floor (SQLite)                  │
└─────────────────────────────────────────────┘
```

### How This Could Be Improved Further

1. **Progress Tracking on Upload**: Firebase Storage's `putFile()` returns a `UploadTask` that emits progress events. Surfacing this as a percentage in the UI (e.g., a `LinearProgressIndicator`) would give users feedback during large uploads. This would require extending `ArticleUploadState` with an `uploadProgress` field.

2. **Image Compression Before Upload**: Adding `flutter_image_compress` to resize and compress selected images before uploading would reduce bandwidth usage and Storage costs significantly for users on mobile data.

3. **Offline Draft Persistence**: The `ArticleUploadCubit` could write form state to the Floor database as a draft whenever the user navigates away. On next app launch, the form would auto-populate from the saved draft, preventing data loss.

---

## 7. Architecture Notes

### Key Files Reference

| Layer | File | Purpose |
|-------|------|---------|
| Domain | `domain/entities/article.dart` | Pure Dart ArticleEntity (11 fields) |
| Domain | `domain/repository/article_repository.dart` | Abstract repository interface |
| Domain | `domain/usecases/upload_article.dart` | Upload use case |
| Domain | `domain/usecases/upload_article_thumbnail.dart` | Thumbnail upload use case |
| Domain | `domain/usecases/get_user_articles.dart` | User articles fetch use case |
| Data | `data/models/article.dart` | ArticleModel with Firestore serialization |
| Data | `data/data_sources/firestore/` | Firestore read/write implementation |
| Data | `data/data_sources/storage/` | Firebase Storage upload implementation |
| Data | `data/repository/article_repository_impl.dart` | Unified repository implementation |
| Presentation | `presentation/bloc/article/upload/` | ArticleUploadCubit + states |
| Presentation | `presentation/bloc/article/user/` | UserArticlesCubit + states |
| Presentation | `presentation/pages/upload_article/` | Upload form screen |
| Presentation | `presentation/pages/user_articles/` | User articles list screen |
| Config | `injection_container.dart` | GetIt DI registrations |
| Config | `config/routes/routes.dart` | Named route definitions |

### Dependency Injection Order

GetIt registrations follow this order to respect initialization dependencies:

1. External services (Dio, Floor database, Firebase instances)
2. Data sources (Remote, Firestore, Storage, Local)
3. Repository implementations (depend on data sources)
4. Use cases (depend on repository interfaces)
5. BLoCs/Cubits (depend on use cases, registered as factories)

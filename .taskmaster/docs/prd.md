# Product Requirements Document: Symmetry News App — Article Upload Feature

## Overview
The Symmetry News App is an existing Flutter + Firebase application that displays news articles fetched from a remote API. The goal of this assignment is to extend the app with an **Article Upload Feature** that allows journalists (users) to author and publish their own articles, stored persistently in Firebase Firestore with thumbnails in Firebase Cloud Storage. The implementation must adhere strictly to Symmetry's Clean Architecture, coding guidelines, contribution guidelines, and architecture violation rules.

---

## Tech Stack
- **Frontend**: Flutter (Dart), Flutter BLoC (cubits + blocs), Clean Architecture (3 layers), get_it (DI), Floor (local DB), Retrofit (API client)
- **Backend**: Firebase Firestore (NoSQL), Firebase Cloud Storage (media), Firebase Local Emulator Suite (local dev)
- **State Management**: flutter_bloc ^8.1.2
- **DI**: get_it ^7.6.0

---

## Core Values (Evaluation Criteria)
1. **Truth is King** — Make opinionated technical decisions and justify them.
2. **Total Accountability** — Own code quality and outcomes.
3. **Maximally Overdeliver** — Exceed the minimum spec: add extra features, animations, or improvements wherever natural.

---

## Part 1: Backend

### Task 1.1 — Design Article Firestore Schema
Design the Firestore NoSQL schema for the `articles` collection. The schema must:
- Mirror the fields of the existing `ArticleEntity`: `author`, `title`, `description`, `url`, `publishedAt`, `content`
- Add a `thumbnailURL` field that is a string reference to a file path in Firebase Cloud Storage under the folder `media/articles/`
- Add a Firestore auto-generated document `id`
- Add a `createdAt` timestamp field
- Add an `isUserArticle: bool` flag to distinguish user-uploaded articles from API-fetched ones

Document this schema in `backend/docs/DB_SCHEMA.md`.

**Acceptance Criteria:**
- `backend/docs/DB_SCHEMA.md` exists with full schema definition
- Schema includes all required fields with types and descriptions
- `thumbnailURL` references `media/articles/{filename}` in Cloud Storage

---

### Task 1.2 — Implement Firestore Schema
Create the Firebase project with:
- Firebase Firestore enabled
- Firebase Cloud Storage enabled
- Firebase Local Emulator Suite enabled (ports: Firestore 8080, Storage 9199)
- Collection: `articles` using the designed schema

**Acceptance Criteria:**
- Firebase project created and configured
- `articles` collection initialized in Firestore
- Cloud Storage bucket has `media/articles/` folder structure
- Local emulator runs via `firebase emulators:start`

---

### Task 1.3 — Firestore & Storage Security Rules
Write and deploy Firestore security rules in `backend/firestore.rules`:
- Allow public reads on `articles`
- Allow authenticated writes (create/update/delete) on `articles`
- Validate required fields on create: `title`, `content`, `author`, `thumbnailURL`, `publishedAt`, `createdAt`
- Validate `thumbnailURL` is a non-empty string

Write Storage rules in `backend/storage.rules`:
- Allow public reads on `media/articles/**`
- Allow authenticated writes on `media/articles/**`
- Restrict file size to 10MB max
- Restrict content types to images only

**Acceptance Criteria:**
- Rules deployed and validated in Firebase console
- Rules prevent unauthenticated writes
- Rules enforce required fields on create

---

## Part 2: Frontend

### Task 2.0 — Firebase + Flutter Setup
Connect the Flutter frontend to the Firebase project:
- Run `flutterfire configure` to generate `firebase_options.dart`
- Initialize Firebase in `main.dart` via `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
- Firebase dependencies already present in `pubspec.yaml`: `firebase_core`, `cloud_firestore`, `firebase_storage`
- Update `backend/.firebaserc` with the correct project ID

**Acceptance Criteria:**
- App compiles and runs with Firebase initialized
- No Firebase connection errors at startup

---

### Task 2.1 — Domain Layer (Business Layer)
Implement the domain layer for the article upload feature. All domain code must be pure Dart — no Firebase, Flutter, or external project imports (except `core/`).

#### 2.1.1 — Extend ArticleEntity
Extend the existing `ArticleEntity` at `features/daily_news/domain/entities/article.dart` to add:
- `thumbnailURL: String?` — Cloud Storage download URL or path
- `isUserArticle: bool` — distinguishes user-uploaded articles from API articles (default: `false`)
- `createdAt: String?` — ISO 8601 upload timestamp

#### 2.1.2 — New Repository Interface Methods
Extend `ArticleRepository` at `features/daily_news/domain/repository/article_repository.dart` with:
- `Future<DataState<void>> uploadArticle(ArticleEntity article)` — persist article to Firestore
- `Future<DataState<String>> uploadArticleThumbnail(String filePath)` — upload image to Cloud Storage, return download URL
- `Future<DataState<List<ArticleEntity>>> getUserArticles()` — fetch user-uploaded articles from Firestore

#### 2.1.3 — Use Cases
Create the following use cases in `features/daily_news/domain/use_cases/`:

**`UploadArticleUseCase`** (`upload_article.dart`):
- Params: `UploadArticleParams(ArticleEntity article)`
- Calls `repository.uploadArticle(params.article)`

**`UploadArticleThumbnailUseCase`** (`upload_article_thumbnail.dart`):
- Params: `UploadThumbnailParams(String filePath)`
- Calls `repository.uploadArticleThumbnail(params.filePath)`
- Returns `DataState<String>` with the Cloud Storage download URL

**`GetUserArticlesUseCase`** (`get_user_articles.dart`):
- Params: `NoParams` (reuse core `NoParams` if it exists, or define one)
- Calls `repository.getUserArticles()`
- Returns `DataState<List<ArticleEntity>>`

Each use case implements the abstract `UseCase<Type, Params>` base class from `core/usecase/`.

**Acceptance Criteria:**
- All domain classes are pure Dart (no Firebase or Flutter imports)
- Repository interface defines all needed contracts as abstract methods
- Each use case has exactly one responsibility
- Use cases can return mock data initially (before data layer is wired)

---

### Task 2.2 — Presentation Layer

#### 2.2.1 — BLoC / Cubits for Article Upload
Create `ArticleUploadCubit` in `features/daily_news/presentation/bloc/article/upload/`:

**States** (`article_upload_state.dart`):
- `ArticleUploadInitial`
- `ArticleUploadLoading`
- `ArticleUploadSuccess`
- `ArticleUploadFailure(String errorMessage)`

**Cubit** (`article_upload_cubit.dart`):
- Depends on `UploadArticleUseCase` and `UploadArticleThumbnailUseCase`
- Method: `uploadArticle(ArticleEntity article, String? thumbnailFilePath)`
  - If `thumbnailFilePath` is provided: upload thumbnail first, get URL, then upload article with URL
  - Emits `ArticleUploadLoading` → `ArticleUploadSuccess` or `ArticleUploadFailure`

Create `UserArticlesCubit` in `features/daily_news/presentation/bloc/article/user/`:

**States** (`user_articles_state.dart`):
- `UserArticlesInitial`
- `UserArticlesLoading`
- `UserArticlesLoaded(List<ArticleEntity> articles)`
- `UserArticlesError(String message)`

**Cubit** (`user_articles_cubit.dart`):
- Depends on `GetUserArticlesUseCase`
- Method: `fetchUserArticles()`

#### 2.2.2 — UI Screens
Implement screens following the Figma prototype style. All screens go in `features/daily_news/presentation/pages/`.

**Article Upload Screen** (`upload_article/upload_article_screen.dart`):
- Form fields: Title (required), Author (required), Description, Content (required, multi-line), Published Date (date picker, required)
- Thumbnail picker: image from device gallery or camera
- Thumbnail preview widget (shown after selection)
- Submit button with loading state (disabled during upload)
- Success feedback: SnackBar or navigation back with success message
- Error feedback: SnackBar or inline error display
- Client-side validation before submission

**User Articles Screen** (`user_articles/user_articles_screen.dart`):
- List view of user-uploaded articles using the same card style as the existing news feed
- Pull-to-refresh to reload articles
- Empty state widget when no articles have been uploaded yet
- Navigate to the existing article detail screen on card tap

**Navigation Integration:**
- Add named routes in `config/routes/routes.dart` for both new screens
- Add a Floating Action Button (FAB) or dedicated tab in `DailyNews` home screen to navigate to the upload screen
- Add a navigation entry point to the User Articles screen (e.g., app bar icon or bottom nav)

**Acceptance Criteria:**
- Upload screen validates all required fields before calling the cubit
- Image picker allows selecting from gallery and camera
- Thumbnail preview is displayed before submission
- Loading indicator is shown during upload
- Success navigates back or shows confirmation
- Error is clearly displayed to the user
- User Articles screen lists uploaded articles and supports pull-to-refresh

---

### Task 2.3 — Data Layer

#### 2.3.1 — Firestore Article Data Source
Create `FirestoreArticleDataSource` (abstract + implementation) in `features/daily_news/data/data_sources/remote/`:

**Abstract interface:**
```dart
abstract class FirestoreArticleDataSource {
  Future<void> uploadArticle(ArticleModel article);
  Future<List<ArticleModel>> getUserArticles();
}
```

**Implementation** (`FirestoreArticleDataSourceImpl`):
- Imports `cloud_firestore` (only place in the app where Firestore is imported)
- `uploadArticle`: calls `FirebaseFirestore.instance.collection('articles').add(article.toFirestore())`
- `getUserArticles`: queries `articles` collection where `isUserArticle == true`, ordered by `createdAt` descending
- Throws exceptions on failure (never returns error objects from data sources per violation 1.2.1)

#### 2.3.2 — Cloud Storage Data Source
Create `FirebaseStorageDataSource` (abstract + implementation) in `features/daily_news/data/data_sources/remote/`:

**Abstract interface:**
```dart
abstract class FirebaseStorageDataSource {
  Future<String> uploadThumbnail(String filePath);
}
```

**Implementation** (`FirebaseStorageDataSourceImpl`):
- Imports `firebase_storage` (only place in the app where Storage is imported)
- `uploadThumbnail`: uploads file to `media/articles/{uuid}.{ext}`, returns download URL
- Throws exceptions on failure

#### 2.3.3 — Article Model Extensions
Extend `ArticleModel` at `features/daily_news/data/models/article.dart`:
- Add `fromFirestore(DocumentSnapshot doc)` factory constructor
- Add `toFirestore()` method returning `Map<String, dynamic>`
- Add `toEntity()` method for conversion back to `ArticleEntity`
- Ensure new `ArticleEntity` fields (`thumbnailURL`, `isUserArticle`, `createdAt`) are handled

#### 2.3.4 — Repository Implementation
Extend `ArticleRepositoryImpl` at `features/daily_news/data/repository/article_repository_impl.dart`:
- Add `FirestoreArticleDataSource` and `FirebaseStorageDataSource` as constructor dependencies
- Implement `uploadArticle`: delegates to `FirestoreArticleDataSource`, wraps in `DataSuccess`/`DataFailed`
- Implement `uploadArticleThumbnail`: delegates to `FirebaseStorageDataSource`, wraps result
- Implement `getUserArticles`: delegates to `FirestoreArticleDataSource`, maps models to entities

#### 2.3.5 — Dependency Injection
Update `injection_container.dart` to register:
- `FirestoreArticleDataSourceImpl` as `FirestoreArticleDataSource` (singleton)
- `FirebaseStorageDataSourceImpl` as `FirebaseStorageDataSource` (singleton)
- `UploadArticleUseCase` (singleton)
- `UploadArticleThumbnailUseCase` (singleton)
- `GetUserArticlesUseCase` (singleton)
- `ArticleUploadCubit` (factory)
- `UserArticlesCubit` (factory)

**Acceptance Criteria:**
- All Firebase SDK calls occur exclusively in data sources
- Repository implementation catches exceptions and wraps them in `DataFailed`
- DI is wired end-to-end with no missing registrations
- End-to-end flow works: fill form → pick image → submit → article in Firestore + image in Cloud Storage

---

## Part 3: Report

### Task 3.1 — Write Final Report
Write the project report at `docs/REPORT.md` following `docs/REPORT_INSTRUCTIONS.md`:

1. **Introduction** — Initial feelings, personal context, experience level
2. **Learning Journey** — Technologies learned (Flutter, Firebase, BLoC, Clean Architecture), resources used, how knowledge was applied
3. **Challenges Faced** — Obstacles encountered, how they were resolved, lessons learned
4. **Reflection and Future Directions** — Overall experience, technical and professional growth, ideas for future improvements
5. **Proof of the Project** — Screenshots and/or screen recordings of the working app
6. **Overdelivery** — Any extra features implemented, prototypes created, suggestions for improvement
7. **Extra Sections** (optional) — Diagrams, metrics, architecture notes, code snippets

---

## Architecture Constraints (Non-Negotiables)

These rules come directly from `docs/ARCHITECTURE_VIOLATIONS.md` and `docs/CODING_GUIDELINES.md`:

| Layer | Rule |
|-------|------|
| Domain | Pure Dart only — no Firebase, Flutter, or other project-layer imports |
| Data Sources | Only place to import and use Firebase SDKs (Firestore, Storage) |
| Repository Interface | Returns `DataState<T>` (never raw models) |
| Models | Must extend an Entity; must have `toEntity()` and `fromRawData`/`fromFirestore` |
| Repository Impl | Named `{Interface}Impl`; only imports data sources |
| Blocs/Cubits | Only place to call use cases; no business logic; no data layer imports |
| Screens/Widgets | No data layer access; delegate all logic to blocs/cubits |

---

## Folder Structure for New Code

```
starter-project/
  backend/
    docs/
      DB_SCHEMA.md                                     (new)
    firestore.rules                                    (update)
    storage.rules                                      (update)
  frontend/lib/
    features/
      daily_news/
        data/
          data_sources/
            remote/
              firestore_article_data_source.dart       (new)
              firebase_storage_data_source.dart        (new)
          models/
            article.dart                               (extend: fromFirestore, toFirestore, toEntity)
          repository/
            article_repository_impl.dart               (extend: new method implementations)
        domain/
          entities/
            article.dart                               (extend: thumbnailURL, isUserArticle, createdAt)
          repository/
            article_repository.dart                    (extend: new abstract method signatures)
          use_cases/
            upload_article.dart                        (new)
            upload_article_thumbnail.dart              (new)
            get_user_articles.dart                     (new)
        presentation/
          bloc/
            article/
              upload/
                article_upload_cubit.dart              (new)
                article_upload_state.dart              (new)
              user/
                user_articles_cubit.dart               (new)
                user_articles_state.dart               (new)
          pages/
            upload_article/
              upload_article_screen.dart               (new)
            user_articles/
              user_articles_screen.dart                (new)
          widgets/
            thumbnail_picker_widget.dart               (new)
            article_upload_form.dart                   (new)
    injection_container.dart                           (update: register new dependencies)
    config/
      routes/
        routes.dart                                    (update: add new named routes)
    main.dart                                          (update: Firebase.initializeApp)
  docs/
    REPORT.md                                          (new)
```

---

## Verification Checklist
- [ ] `firebase emulators:start` runs without errors
- [ ] `flutter pub get && flutter run` builds and launches the app
- [ ] Existing news feed loads API articles without regression
- [ ] Upload form validates required fields client-side
- [ ] Image picker opens gallery/camera and shows preview
- [ ] Submitting form uploads thumbnail to Cloud Storage `media/articles/`
- [ ] Article document is created in Firestore `articles` collection
- [ ] User Articles screen lists uploaded articles with pull-to-refresh
- [ ] Firestore security rules block unauthenticated writes (test in emulator)
- [ ] Storage security rules block unauthenticated uploads (test in emulator)
- [ ] `docs/REPORT.md` exists and covers all required sections
- [ ] `backend/docs/DB_SCHEMA.md` exists with full schema

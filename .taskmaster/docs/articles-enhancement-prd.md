# Overview

This initiative improves the **daily news** feature in the Flutter app (`features/daily_news/`) with three enhancements that address scalability, post-publish editing, and content authoring quality:

1. **Firestore cursor-based pagination** — The current `getUserArticles` query fetches every user-uploaded article in a single read. As the collection grows this causes unnecessary Firestore reads, increased latency, and degraded scroll performance. Cursor-based pagination (`limit` + `startAfter`) keeps each request bounded.

2. **Article editing** — Signed-in users can currently upload and delete articles but cannot edit them after publishing. This feature adds an owner-only update path so authors can fix typos, update content, or swap thumbnails without deleting and re-uploading.

3. **Rich text (markdown) editor** — The upload screen uses a plain multiline `TextFormField` for article content. The detail screen already renders markdown via `ArticleMarkdownBody` and `flutter_markdown`. Replacing the compose field with a toolbar-equipped markdown editor closes the gap between authoring and rendering.

The app follows **Clean Architecture** (data / domain / presentation), uses **GetIt** for dependency injection, and merges Firestore user articles with News API results in `ArticleRepositoryImpl`.

# Core Features

## Firestore Cursor-Based Pagination

- **What it does**: Replaces the unbounded `getUserArticles()` Firestore query with a paginated variant that returns a fixed page size (e.g., 20 articles) plus a cursor for the next page.
- **Why it's important**: Firestore charges per document read and the client must deserialize every result. Without pagination the home feed becomes slower and more expensive as users publish more articles.
- **How it works**: A new data-source method `getUserArticlesPage({required int limit, DocumentSnapshot? startAfter})` uses the existing `isUserArticle == true` / `orderBy('createdAt', descending: true)` query with `.limit(limit)` and optional `.startAfterDocument(startAfter)`. The repository returns a result object containing the article list, the last document snapshot (cursor), and a `hasMore` flag. The presentation layer (Cubit) holds the cursor and appends pages on a "Load more" trigger. News API results are fetched once per session and merged with each Firestore page.

## Article Editing (Owner-Only)

- **What it does**: Allows the author of a user-uploaded article to edit its title, description, content, and thumbnail after publishing.
- **Why it's important**: Without editing, the only way to correct a published article is to delete and re-upload it, losing the original `createdAt` timestamp and Firestore document ID.
- **How it works**:
  - **Domain**: New `UpdateArticleUseCase` that accepts an `ArticleEntity` with a non-null `firestoreId`.
  - **Data**: `FirestoreArticleDataSource.updateArticle(String firestoreId, ArticleModel patch)` calls `doc(firestoreId).update(patch.toFirestoreUpdate())` where `toFirestoreUpdate()` excludes immutable fields (`userId`, `createdAt`, `isUserArticle`).
  - **Presentation**: An `EditArticleCubit` (or extension of the upload cubit) pre-fills form fields from the existing article. An "Edit" button appears on the article detail screen only when `article.userId == currentUser.uid && article.isUserArticle == true`.
  - **Security**: Firestore rules must be tightened so that `update` requires `resource.data.userId == request.auth.uid`. The same ownership check is added to `create` to prevent userId spoofing (`request.resource.data.userId == request.auth.uid`).

## Markdown Editor Widget

- **What it does**: Replaces the plain `TextFormField` for article content on the upload and edit screens with a markdown-aware editor that includes a formatting toolbar (bold, italic, heading, bulleted list).
- **Why it's important**: Users currently type raw markdown syntax without visual aids. A toolbar and live preview lower the barrier to well-formatted articles and match the rendering already present in the detail view.
- **How it works**: Integrate a Flutter markdown editor package (evaluate `markdown_editable_textinput` or similar lightweight, null-safe package; `flutter_quill` is an alternative if richer formatting is needed but adds significant weight). The editor outputs a plain markdown string stored in the existing `content` field — no schema change required. Both the upload and edit screens share the same editor widget. The existing `ArticleMarkdownBody` widget continues to handle rendering on the detail screen.

# User Experience

## User Personas

- **Author**: An authenticated user who publishes articles and later needs to correct or update them. Benefits from editing and the markdown toolbar.
- **Reader**: Any user (authenticated or not) browsing the feed. Benefits from faster pagination and better-formatted articles. Their experience is otherwise unchanged.

## Key User Flows

1. **Home feed with pagination**: User opens the app → first page of articles loads (Firestore + News API merged). User scrolls to the bottom → "Load more" button or infinite-scroll trigger fetches the next Firestore page and appends to the list. A loading indicator shows during fetch; an error snackbar appears on failure with a retry option.

2. **Upload with markdown editor**: User taps the upload FAB → the upload form now shows a markdown editor with a toolbar instead of a plain text field. The rest of the flow (title, author, description, thumbnail, submit) is unchanged.

3. **Edit an article**: User views their own article detail → an "Edit" icon button appears in the app bar. Tapping it navigates to the edit screen (same layout as upload) with all fields pre-filled. User modifies content and taps "Save". The update use case patches the Firestore document. On success the user returns to the detail screen which reflects the changes.

## UI/UX Considerations

- The "Edit" button must only appear for the article's owner; it should be completely absent for other users and for News API articles.
- The pagination trigger (button or scroll) should feel seamless; avoid full-screen loading states after the initial load.
- The markdown editor toolbar should be compact and not obscure the editing area on small screens.
- On the edit screen, if the user presses back with unsaved changes, show a discard confirmation dialog (optional for MVP, required for polish).

# Technical Architecture

## System Components

- **Data layer**: Extend `FirestoreArticleDataSource` (interface and implementation) with `getUserArticlesPage` and `updateArticle`. Add a `toFirestoreUpdate()` method to `ArticleModel` that returns only mutable fields.
- **Domain layer**: Add `UpdateArticleUseCase`. Add `GetArticlesPageUseCase` that wraps the paginated repository call. Update `ArticleRepository` interface with the new methods.
- **Presentation layer**: New `EditArticleCubit` (or adapt `ArticleUploadCubit` with an editing mode). Modify the home-feed cubit to hold pagination state (cursor, hasMore, isLoadingMore). Add a shared `MarkdownEditorWidget` used by both upload and edit screens.
- **DI**: Register new use cases and cubits in `injection_container.dart`.
- **Routing**: Add an edit-article route in `routes.dart` that receives the article to edit.

## Data Models

No breaking changes to `ArticleEntity` or `ArticleModel`. The `firestoreId` and `userId` fields already exist and are populated on Firestore reads. An optional `updatedAt` timestamp field may be added for display purposes — if added, include it in `toFirestoreUpdate()` and document the new Firestore index.

## APIs and Integrations

- **Firestore**: New `update` operation on `articles/{docId}`; paginated `get` with cursor.
- **News API**: No changes. Results are fetched once per session and cached in-memory for merge with each Firestore page.
- **Firebase Storage**: No changes; thumbnail upload/replace reuses existing `FirebaseStorageDataSource.uploadThumbnail`.

## Infrastructure Requirements

- **Firestore security rules** (`backend/firestore.rules`): Update `create` and `update` rules to enforce `userId == request.auth.uid` ownership. Maintain existing `delete` ownership check.
- **Firestore indexes**: If `updatedAt` is added, a composite index on `(isUserArticle, updatedAt desc)` may be needed. Verify via Firestore console or `firestore.indexes.json`.

# Development Roadmap

## Phase A — Security and Edit Backend

- Update `backend/firestore.rules` to add ownership checks on `create` and `update`.
- Add `updateArticle` method to `FirestoreArticleDataSource` interface and `FirestoreArticleDataSourceImpl`.
- Add `toFirestoreUpdate()` to `ArticleModel`.
- Create `UpdateArticleUseCase` in domain layer.
- Add `updateArticle` to `ArticleRepository` interface and `ArticleRepositoryImpl`.
- Create `EditArticleCubit` and `EditArticleState`.
- Build edit article screen (reuse upload form layout, pre-fill fields, call update on submit).
- Add edit-article route to `routes.dart`.
- Add "Edit" button to article detail screen (owner-only visibility).
- Register new dependencies in `injection_container.dart`.
- Write unit tests for `UpdateArticleUseCase`, `EditArticleCubit`, and the Firestore update method.

## Phase B — Pagination

- Add `getUserArticlesPage` to `FirestoreArticleDataSource` interface and implementation.
- Create a pagination result model (articles list, last document cursor, hasMore flag).
- Add `GetArticlesPageUseCase` in domain layer.
- Update `ArticleRepository` interface and `ArticleRepositoryImpl` with paginated method.
- Modify the home-feed cubit to hold pagination state and expose a `loadMore()` method.
- Update the home feed UI with a "Load more" button or infinite-scroll listener.
- Define News API caching strategy: fetch once per session, merge cached results with each Firestore page.
- Write unit tests for the paginated data source, repository, and cubit.

## Phase C — Markdown Editor

- Evaluate and add a Flutter markdown editor package to `pubspec.yaml`.
- Create a shared `MarkdownEditorWidget` with a formatting toolbar (bold, italic, heading, list).
- Replace the content `TextFormField` in the upload screen with `MarkdownEditorWidget`.
- Use the same `MarkdownEditorWidget` on the edit screen.
- Ensure the editor outputs a plain markdown string compatible with the existing `content` field.
- Write widget tests for toolbar interactions and content submission.

## Future Enhancements (Out of Scope)

- Optimistic UI — show article immediately on upload before Firestore confirms.
- Notifications — Firebase Cloud Messaging for new article alerts.
- Offline editing — cache drafts locally for later sync.
- Image embedding in markdown content body.

# Logical Dependency Chain

1. **Firestore security rules** — Must be deployed first to safely allow update operations. Blocks the edit feature. Independent of client code.
2. **Update article use case + data layer** — Builds the backend path for editing. Depends on rules being in place for safe testing.
3. **Edit article UI + cubit** — Depends on the update use case. Shares form layout with the existing upload screen, so the upload screen structure should be stable first.
4. **Pagination data layer + use case** — Largely independent of editing. Can be developed in parallel with Phase A once the `FirestoreArticleDataSource` interface shape is agreed upon.
5. **Pagination UI** — Depends on the pagination use case. Modifies the home-feed cubit and list view.
6. **Markdown editor widget** — Depends on both upload and edit screens being stable. Applied to both screens simultaneously to avoid divergent authoring experiences.

The fastest path to visible user value is: **rules → update use case → edit screen** (user can edit articles). Then **pagination** (feed scales). Then **markdown editor** (authoring polish).

# Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Merged feed complicates "load more" | Users see duplicate or inconsistent ordering when Firestore pages are merged with News API results | Paginate only Firestore articles; fetch News API once per session and prepend/merge deterministically; document the merge ordering rule |
| Firestore rule change breaks existing upload flow | Users cannot publish new articles if the ownership check is too strict | Add `request.resource.data.userId == request.auth.uid` on create (the client already sets `userId` to `currentUser.uid` in `ArticleUploadCubit`); deploy rules alongside the client update; E2E test upload after rule change |
| Markdown editor package adds significant bundle size or has platform issues | Larger app binary; potential crashes on specific platforms | Prefer a lightweight, well-maintained package; run smoke tests on iOS and Android before committing; fall back to the existing `TextFormField` with a markdown syntax hint if the package is unsuitable |
| Large markdown bodies approach Firestore document size limit | Write failures for very long articles | Add client-side content length validation (e.g., 50,000 characters) aligned with existing field constraints in `DB_SCHEMA.md`; show a character counter in the editor |
| Edit screen diverges from upload screen causing maintenance overhead | Two similar but slightly different forms to maintain | Extract a shared `ArticleFormWidget` used by both upload and edit screens; differences (submit label, pre-fill behavior) are parameterized |

# Appendix

## Existing Schema Reference

The Firestore `articles` collection schema is documented in `backend/docs/DB_SCHEMA.md`. Key fields relevant to this PRD:
- `userId` (string) — owner identifier, set on upload, used for ownership checks
- `firestoreId` — Firestore document ID, stored as a client-side field for convenience
- `content` (string, required) — full article body, currently plain text but rendered as markdown
- `createdAt` (timestamp, required) — immutable after creation
- `isUserArticle` (boolean) — distinguishes user uploads from News API articles

## Current Security Rules

`backend/firestore.rules` currently allows `create` and `update` for any authenticated user with required field keys present. The `delete` rule already checks `resource.data.userId == request.auth.uid`. This PRD requires extending the ownership check to `create` and `update`.

## File References

- Firestore data source: `frontend/lib/features/daily_news/data/data_sources/firestore/firestore_article_data_source_impl.dart`
- Article model: `frontend/lib/features/daily_news/data/models/article.dart`
- Article entity: `frontend/lib/features/daily_news/domain/entities/article.dart`
- Repository: `frontend/lib/features/daily_news/data/repository/article_repository_impl.dart`
- Upload cubit: `frontend/lib/features/daily_news/presentation/bloc/article/upload/article_upload_cubit.dart`
- Upload screen: `frontend/lib/features/daily_news/presentation/pages/upload_article/upload_article.dart`
- Article detail: `frontend/lib/features/daily_news/presentation/pages/article_detail/article_detail.dart`
- Markdown renderer: `frontend/lib/features/daily_news/presentation/widgets/markdown_body_widget.dart`
- DI container: `frontend/lib/injection_container.dart`
- Routes: `frontend/lib/config/routes/routes.dart`
- Firestore rules: `backend/firestore.rules`
- DB schema docs: `backend/docs/DB_SCHEMA.md`

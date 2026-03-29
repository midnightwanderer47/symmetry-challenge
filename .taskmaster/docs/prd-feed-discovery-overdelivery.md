<context>
# Overview

The Symmetry News App already supports uploading journalist-authored articles to Firebase Firestore and displaying them in a dedicated "my articles" screen. However, user-generated content is completely isolated from the main feed, which only shows articles from the remote News API. This creates a fragmented experience where readers miss internal content and journalists feel their work is hidden.

This PRD addresses that gap by merging both article sources into a single home feed, adding search across the combined corpus, introducing a coherent app shell for navigation, and optionally enriching the article lifecycle with edit/delete, theming, and profile features. It builds on the existing upload functionality defined in the base PRD (see Appendix) and targets parity with internal reference implementations used by current Symmetry team members.

The target audience is threefold: **readers** who consume news, **journalists** who publish articles, and **reviewers** (senior developers at Symmetry) who evaluate code quality, architecture adherence, and product completeness.

# Core Features

## Merged home feed
- **What it does:** The home screen displays a single, chronologically sorted list combining articles from Firebase Firestore (user-generated) and the external News API.
- **Why it's important:** Uploaded articles currently live in a separate screen. Without merging, the journalist workflow feels incomplete — publish goes nowhere visible. This is the single highest-impact change for reviewer perception and product coherence.
- **How it works at a high level:**
  - The repository implementation fetches from both Firestore and the News API (in parallel where possible).
  - Results are deduplicated by normalized title (case-insensitive); when both sources contain the same story, the Firestore version is preferred (richer metadata, controlled thumbnails).
  - The merged list is sorted by `publishedAt` descending. Articles missing `publishedAt` fall back to `createdAt` or sort to the end.
  - If one source fails, the other still displays with a non-blocking error indicator (snackbar or inline banner).
  - The `isUserArticle` flag (or equivalent) is preserved so the UI can optionally badge user content.
  - **Acceptance criteria:**
    - With both sources available, the feed shows a mix of user and API articles.
    - With the API down, Firestore-only articles still render.
    - With Firestore empty, behavior matches the previous API-only baseline.

## Search
- **What it does:** A search entry point (app bar icon or dedicated screen) lets users query the same merged pipeline by keyword.
- **Why it's important:** Without search, readers must scroll the entire feed to find content. Discoverability is a core product expectation and a clear differentiator in internal reference apps.
- **How it works at a high level:**
  - The search use case delegates to the repository, which filters Firestore articles by title/content (case-insensitive client-side match) and queries the News API search endpoint (or filters client-side if no search endpoint is available — the chosen approach must be documented).
  - Results are merged and deduplicated with the same logic as the home feed.
  - An explicit empty state is shown when no articles match.
  - **Acceptance criteria:**
    - Searching a keyword unique to a user-uploaded title returns that article.
    - Searching returns API hits when they match.

## Feed refresh
- **What it does:** Users can trigger a refresh of the merged feed via pull-to-refresh or a retry control on error states.
- **Why it's important:** After publishing an article, the journalist needs confidence that the content appears without reinstalling. Refresh is table-stakes UX for any feed.
- **How it works at a high level:**
  - Pull-to-refresh on the home list re-invokes the merged fetch use case.
  - On error screens, a retry button re-triggers the same flow.
  - **Acceptance criteria:**
    - After uploading an article and returning to home, a refresh shows the new item.

## App shell navigation
- **What it does:** A main navigation shell (bottom navigation bar or equivalent) provides top-level access to Feed, Create/Upload, and Profile/Settings.
- **Why it's important:** Currently, upload is only reachable via a FAB on the feed screen. A proper shell makes primary actions visible and accessible in one tap, matching internal reference apps and Figma conventions.
- **How it works at a high level:**
  - A `MainScreen` widget with `BottomNavigationBar` and `IndexedStack` (or equivalent) hosts: Feed, Create Article, and Profile/Settings tabs.
  - Existing named routes and deep links are preserved or updated with test coverage.
  - Feed remains the default landing tab.
  - **Acceptance criteria:**
    - Create/upload is reachable in one tap from the shell.
    - Feed is the default landing experience.

## (Optional) Edit/delete own articles
- **What it does:** From the article detail or "my articles" screen, the author can delete (and optionally edit) their own Firestore articles.
- **Why it's important:** A complete article lifecycle (create → read → update → delete) demonstrates backend maturity and shows total accountability for data management.
- **How it works at a high level:**
  - Delete calls `FirestoreArticleDataSource.deleteArticle(id)` behind a use case + cubit.
  - Edit navigates to a pre-filled upload form and calls an `updateArticle` method.
  - Firestore rules enforce ownership (`request.auth.uid` matching a `userId` field) when non-anonymous auth is in place. With anonymous auth, document the ownership model or defer this feature.
  - **Acceptance criteria:**
    - Security model is documented; no accidental public delete of others' content.

## (Optional) Theme and profile
- **What it does:** Persisted light/dark theme toggle and a minimal profile screen.
- **Why it's important:** Theme persistence via `shared_preferences` and a `ThemeCubit` demonstrate Clean Architecture state management beyond the article domain. A profile screen fills the third tab in the shell.
- **How it works at a high level:**
  - `ThemeCubit` reads/writes theme preference on init/toggle.
  - Profile screen shows display name (and optionally avatar) if backend profile data exists; otherwise renders a stub.

# User Experience

## Personas
- **Reader:** Wants a single place to browse all news (external + internal) and find articles quickly via search.
- **Journalist:** Wants to publish articles and immediately see them in the main feed; expects create/upload to be prominent, not buried.
- **Reviewer (Symmetry senior dev):** Evaluates architecture compliance, code quality, and product completeness. Expects the merged feed to "just work" and the codebase to respect Clean Architecture boundaries.

## Key user flows
1. **Open app → merged feed:** The home screen loads articles from both sources, sorted by date. Pull-to-refresh updates the list.
2. **Search:** Tap search icon → type query → see filtered results from both sources → tap article to view detail.
3. **Publish → verify:** Navigate to Create tab → fill form + pick thumbnail → submit → return to Feed tab → pull-to-refresh → new article appears in the merged list.
4. **Manage own articles:** From profile or "my articles," view published articles → delete or edit (optional flow).

## UI/UX considerations
- The merged feed should be visually indistinguishable from the current feed for API-only articles; user articles simply appear in the same list with an optional badge.
- Search should debounce input to avoid excessive API calls.
- Error states for partial failures (one source down) should be non-blocking — a snackbar or small inline indicator, not a full-screen error replacing available content.
- Bottom navigation labels and icons should follow platform conventions (Material 3 guidelines).
</context>
<PRD>
# Technical Architecture

## System components

### Presentation layer
- **RemoteArticlesCubit** (or equivalent Bloc): Drives the home feed; emits loading / done / error states from the merged use case. Replaces or extends the existing `RemoteArticlesBloc` to consume the merged pipeline.
- **SearchArticleCubit**: Manages search query state and delegates to a search use case that reuses the merge logic.
- **ArticleUploadCubit**: Existing cubit for the upload flow; unchanged.
- **UserArticlesCubit**: Existing cubit for "my articles"; unchanged.
- **ThemeCubit** (optional): Manages persisted light/dark theme state.
- **MainScreen widget**: Shell with `BottomNavigationBar` + `IndexedStack` hosting Feed, Create, Profile tabs.

### Domain layer (pure Dart, no Flutter/Firebase imports)
- **ArticleRepository (interface):** Gains `searchArticles(String query)` (new) alongside existing `getNewsArticles()`. Internally, `getNewsArticles` semantics change to return merged results; document this in code or PR description.
- **GetArticlesUseCase:** Calls `repository.getNewsArticles()` which now returns merged data.
- **SearchArticlesUseCase:** Calls `repository.searchArticles(query)`.
- **DeleteArticleUseCase / UpdateArticleUseCase** (optional): Delegate to repository for Firestore mutations.

### Data layer
- **ArticleRepositoryImpl:** Orchestrates fetches from `FirestoreArticleDataSource` and `NewsApiService` (or `NewsRemoteDataSource`), merges, deduplicates, and sorts.
- **FirestoreArticleDataSource:** Existing; add `deleteArticle` / `updateArticle` if FR5 is implemented.
- **NewsApiService:** Existing Retrofit client; optionally add a search endpoint method.
- **AppDatabase (Floor):** Existing; unchanged for bookmarks.

## Data models
- **ArticleEntity** (domain): Existing fields + `isUserArticle` flag (already present or added as a boolean).
- **ArticleModel** (data): Extends `ArticleEntity`; handles JSON/Firestore parsing. `fromFirebase` and `fromJson` factories already exist.

## APIs and integrations
- **News API:** Existing REST integration via Retrofit. Search uses the `/everything?q=` endpoint if available, or client-side filtering after fetch.
- **Firebase Firestore:** `articles` collection; existing schema with `thumbnailURL`, `publishedAt`, `createdAt`.
- **Firebase Cloud Storage:** `media/articles/` path; existing upload flow.
- **Firebase Auth:** Existing anonymous sign-in via `AuthGate`; rules require `request.auth != null` for writes.

## Infrastructure requirements
- No new infrastructure beyond what the base PRD established (Firebase project, emulators, Flutter SDK).
- `shared_preferences` package added only if FR6 (theme persistence) is implemented.
- `flutter_lints` bumped from `^1.0.0` to `^2.0.0` when touching `pubspec.yaml` (aligns with reference projects).

# Development Roadmap

## Phase 1 — MVP: Merged feed (FR1)
- Modify `ArticleRepositoryImpl.getNewsArticles()` to fetch from both Firestore and News API, merge, deduplicate by title, and sort by `publishedAt` desc.
- Handle partial failures (one source down) gracefully — return available data + error metadata.
- Update or replace `RemoteArticlesBloc` with a cubit that consumes the merged result.
- Add unit tests for the merge/dedupe/sort logic (pure Dart, no Firebase dependency).
- Update home screen to render the merged list (minimal UI change — same `ArticleWidget` tiles).

## Phase 2 — Search + refresh (FR2, FR3)
- Add `searchArticles(String query)` to the repository interface and implementation, reusing the merge pipeline with query filtering.
- Create `SearchArticlesUseCase` and `SearchArticleCubit`.
- Build search UI: app bar action → search screen with text field, results list, empty state.
- Add pull-to-refresh to the home feed (`RefreshIndicator` wrapping the `ListView`).
- Register new use case and cubit in `injection_container.dart`.
- Add route for `/SearchNews` in `routes.dart`.

## Phase 3 — App shell navigation (FR4)
- Create `MainScreen` with `BottomNavigationBar` (Feed, Create, Profile/Settings tabs) and `IndexedStack`.
- Move `DailyNews` (feed) into the Feed tab; `UploadArticleView` into the Create tab.
- Update `routes.dart` to use `MainScreen` as the home route.
- Update existing tests that reference the old home widget.

## Phase 4 — Future enhancements (FR5, FR6)
- **Delete own articles:** Add `deleteArticle` to repository interface, data source, use case, cubit; update Firestore rules for ownership if auth model allows.
- **Edit own articles:** Add `updateArticle` flow with pre-filled form.
- **Theme persistence:** Add `shared_preferences` dependency, `ThemeCubit`, `SettingsRepository`.
- **Profile screen:** Stub or full implementation depending on backend profile schema availability.
- **Launcher icon:** Add `flutter_launcher_icons` config for branded app identity.

# Logical Dependency Chain

1. **Foundation — repository merge logic (Phase 1):** Everything else depends on the repository returning a unified article list. This is pure data-layer work with no UI changes required initially; it can be unit-tested in isolation.
2. **Visible result — home feed renders merged data (Phase 1 cont.):** Swap the bloc/cubit to consume the new merged output. This is the fastest path to a visible, working front end showing user articles alongside API articles.
3. **Search reuses merge pipeline (Phase 2):** The search use case and cubit depend on the merge infrastructure from Phase 1. Building search before merge would duplicate logic.
4. **Refresh depends on merged cubit (Phase 2):** Pull-to-refresh simply re-invokes the cubit's fetch method; trivial once the cubit exists.
5. **Shell is independent of merge (Phase 3):** The bottom navigation shell can technically be built in parallel with Phase 1, but is best sequenced after the merged feed is confirmed working so the Feed tab has real content to display.
6. **Optional features build on all prior work (Phase 4):** Delete/edit require the Firestore data source methods and a working merged feed to verify removal. Theme/profile are independent but benefit from the shell (third tab).

# Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Duplicate stories across Firestore and API | Confusing repeated entries in feed | Title-based case-insensitive deduplication; optional secondary check on URL |
| News API rate limits during search | Empty or error results | Debounce search input (300-500ms); cache last merged list; document rate limit in README |
| Anonymous auth limits ownership enforcement | Cannot safely scope delete to "my" articles | Keep deletes behind `isUserArticle` client-side check; defer server-side ownership rules until auth model is upgraded; document trade-off |
| Firestore cold-start latency | Slow initial feed load | Fetch both sources in parallel (`Future.wait`); show loading indicator only until first source responds if feasible |
| Breaking existing tests | Regression | Update widget and integration tests that reference `RemoteArticlesBloc` or the old home scaffold; run full test suite before merge |

# Appendix

## Relation to base PRD
This document extends the original assignment PRD at [.taskmaster/docs/prd.md](./prd.md), which covers the article upload feature, Firestore schema, Storage rules, and Firebase setup. All requirements here assume that base PRD work is complete or in progress.

## Architecture references
- [docs/APP_ARCHITECTURE.md](../../docs/APP_ARCHITECTURE.md) — Clean Architecture layer rules
- [docs/CODING_GUIDELINES.md](../../docs/CODING_GUIDELINES.md) — Code style and conventions
- [docs/ARCHITECTURE_VIOLATIONS.md](../../docs/ARCHITECTURE_VIOLATIONS.md) — Known violations and how to avoid them
- [docs/CONTRIBUTION_GUIDELINES.md](../../docs/CONTRIBUTION_GUIDELINES.md) — PR and commit conventions

## Open questions
- Should search include saved/offline articles from Floor? Default recommendation: no — only remote API + Firestore merge unless product asks otherwise.
- When deduping, should thumbnail/display prefer Firestore `thumbnailURL` or API `urlToImage`? Default recommendation: prefer Firestore when the duplicate is identified as the same story.

## Generating Taskmaster tasks from this PRD
```bash
task-master parse-prd .taskmaster/docs/prd-feed-discovery-overdelivery.md --append
```
Then optionally:
```bash
task-master analyze-complexity --research
task-master expand --all --research
```
</PRD>

<context>
# Overview

Authenticated publishers need a clear, confident flow to create articles with a thumbnail, rich text-style body content, and explicit feedback when publishing completes. Today the Flutter app’s **Upload Article** screen supports basic fields and Firestore upload, but publishers lack: (1) discoverable re-selection of the thumbnail from the preview, (2) structured formatting (headings, bold) in the body, (3) obvious confirmation that the article was published, and (4) a blocking loading experience during the publish operation.

This PRD scopes improvements to the **publisher upload/publish path** only (upload screen, navigation return path, and article reading view for rendered content). It does not change backend contracts beyond storing markdown as plain text in existing `content` (and optionally `description`) fields unless explicitly extended.

**Problem:** Publishers may abandon or distrust the flow because feedback is weak, formatting is limited to a single plain text block, and loading/success states are easy to miss.

**Audience:** Signed-in users who upload user articles (`isUserArticle` / Firestore user content).

**Value:** Higher trust, richer articles, and fewer support questions about “did my article go live?”

# Core Features

## F1 — Thumbnail: change photo after selection

- **What it does:** After choosing a thumbnail, the user can change it without confusion—both via the existing control and by tapping the image preview.
- **Why it matters:** Users expect “tap the photo to replace it”; relying only on a secondary button reduces discoverability.
- **How it works:** Keep `ImagePicker` gallery as today; ensure “Pick Thumbnail” / equivalent remains available; add tap target on the preview (e.g. `InkWell` / `GestureDetector`) that invokes the same pick flow. Optional: short hint (“Tap to change”) on or under the preview.

## F2 — Markdown (or subset) for article body

- **What it does:** Publishers can use lightweight markup in **Content** for subheadings, bold, lists, and line breaks—stored as a string (e.g. CommonMark-compatible markdown) in the existing `content` field.
- **Why it matters:** Editorial structure improves readability without a full WYSIWYG editor in MVP.
- **How it works:** Authoring remains primarily a multiline text field with helper text listing supported syntax; **Article detail** renders `content` with a markdown renderer (e.g. `flutter_markdown`), with a `TextStyle`/theme aligned to current article typography. Description may stay plain text in MVP or use the same renderer—product choice in implementation.

## F3 — Publish success feedback

- **What it does:** After a successful publish, the user sees an unmistakable confirmation before or after leaving the screen.
- **Why it matters:** Silent `Navigator.pop` does not communicate that the server accepted the article.
- **How it works:** At minimum: show a `SnackBar` (or dialog) with copy such as “Article published” when upload succeeds; optionally `await` the route result on the home FAB and show the SnackBar on the feed scaffold when `true` is returned. Optionally trigger article list refresh so the new item appears without manual refresh.

## F4 — Loading state during publish

- **What it does:** While the article (and optional thumbnail) is uploading, the UI shows a clear, blocking loading state—not only a small spinner inside the primary button.
- **Why it matters:** Long uploads on slow networks need a full-screen or modal overlay so users do not navigate away or tap twice.
- **How it works:** When `ArticleUploadLoading` is active, overlay a non-dismissible barrier (or full-screen stack) with centered progress and label (e.g. “Publishing…”). Primary action remains disabled; copy may read **Publish Article** if product prefers that label over “Upload Article.”

# User Experience

## Personas

- **Publisher:** Authenticated user submitting an article; may be non-technical; needs clarity and feedback.
- **Reader:** Sees rendered markdown in article detail; should not see raw `**` unless rendering fails.

## Key user flows

1. Open Upload Article → fill title, author, description, **markdown content**, date → pick/change thumbnail → **Publish Article** → see full-screen loading → success message → return to feed (with optional list refresh).
2. Change thumbnail after first pick: tap preview or “Pick Thumbnail” again → gallery → new image shown.
3. Open published article from feed → content shows headings and bold as formatted text.

## UI/UX considerations

- Accessibility: loading overlay should be announced; success message should not rely on color alone.
- Consistency: match existing app fonts where possible (`Butler` for titles, readable body for markdown).
- Errors: keep existing failure `SnackBar` behavior; loading overlay must clear on failure.
- Scope: no requirement for inline markdown toolbar in MVP unless roadmap adds it.

</context>
<PRD>
# Technical Architecture

## System components

- **Flutter:** `UploadArticleView` ([`frontend/lib/features/daily_news/presentation/pages/upload_article/upload_article.dart`](frontend/lib/features/daily_news/presentation/pages/upload_article/upload_article.dart)), `ArticleUploadCubit`, navigation from home ([`daily_news.dart`](frontend/lib/features/daily_news/presentation/pages/home/daily_news.dart)), article reader ([`article_detail.dart`](frontend/lib/features/daily_news/presentation/pages/article_detail/article_detail.dart)).
- **New dependency:** `flutter_markdown` (or equivalent) for rendering; no server change required if `content` remains a UTF-8 string.

## Data models

- **Article entity / Firestore:** Continue storing `content` as `String`. Markdown is serialized as plain text; no new field strictly required for MVP.
- **Optional future:** `contentFormat: 'markdown' | 'plain'` if the app must support legacy plain-only articles—only add if mixed populations exist.

## APIs and integrations

- **Unchanged:** `UploadArticleUseCase`, thumbnail upload to Storage, Firestore `uploadArticle`.
- **Client-only:** Markdown rendering is entirely in the Flutter reader; no API schema migration for MVP.

## Infrastructure

- None beyond existing Firebase stack.

# Development Roadmap

## Phase 1 — MVP (must ship together for coherent UX)

1. Add markdown dependency and render **content** in `ArticleDetailsView` with `MarkdownBody` (or equivalent), including style sheet tuned to current layout.
2. Upload screen: helper text for supported markdown; full-screen/stack loading overlay when `ArticleUploadLoading`; rename primary button to **Publish Article** if aligned with copy.
3. Success feedback: `SnackBar` on publish success and/or handle `Navigator.pop(context, true)` at the call site with a follow-up SnackBar on home; optionally refresh remote articles cubit.
4. Thumbnail: tap-on-preview to re-open gallery + optional hint text.

## Phase 2 — Future enhancements

- Markdown toolbar or segmented control for bold/heading shortcuts.
- Preview tab (“Preview markdown”) before publish.
- Sanitization policy for untrusted markdown (if HTML embedding becomes a concern).
- `contentFormat` flag for backward compatibility if old articles must render as plain text only.

# Logical Dependency Chain

1. **Foundation:** Add `flutter_markdown` (or chosen package) and prove rendering in article detail with sample string—delivers visible value early.
2. **Authoring hints:** Helper text on upload content field so publishers know what will render—cheap and pairs with (1).
3. **Publish loading overlay:** Depends on existing `ArticleUploadLoading` state only; can ship in parallel with (1) after cubit states are unchanged.
4. **Success feedback:** Depends on successful emission of `ArticleUploadSuccess`; wire SnackBar and/or route result—should follow overlay to avoid duplicate spinners/messages.
5. **Thumbnail tap:** Independent; can be last small UX pass.

Order rationale: readers benefit as soon as markdown renders; publishers need hints + loading + success to complete the trust loop; thumbnail tap is polish.

# Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Existing articles are plain text and look odd if parsed as markdown | MVP: treat all `content` as markdown; benign for plain text. If needed later, add `contentFormat` or detect minimal markdown markers. |
| XSS or unsafe HTML in markdown | Use `flutter_markdown` default safe rendering; avoid raw HTML extension unless sanitized. |
| Double SnackBar (upload screen + home) | Choose one primary surface: prefer home `SnackBar` after `pop` with result, or single SnackBar before pop—document in implementation. |
| Full-screen loader blocks back navigation | Document whether `AppBar` back is disabled during loading (recommended: disable or intercept to avoid duplicate submits). |

# Appendix

## Current implementation notes (baseline)

- Thumbnail: `OutlinedButton.icon` calls `_pickImage` repeatedly; preview image is not tappable ([`upload_article.dart`](frontend/lib/features/daily_news/presentation/pages/upload_article/upload_article.dart)).
- Success: `Navigator.pop(context, true)` only; home FAB does not consume result ([`daily_news.dart`](frontend/lib/features/daily_news/presentation/pages/home/daily_news.dart)).
- Loading: inline `CircularProgressIndicator` on primary button only.
- Reader: `description` and `content` concatenated in a single `Text` widget ([`article_detail.dart`](frontend/lib/features/daily_news/presentation/pages/article_detail/article_detail.dart)).

## Suggested `task-master` usage

```bash
task-master parse-prd .taskmaster/docs/prd-upload-article-publisher-experience.md --append
```

(Optional: use a dedicated tag for this initiative per project workflow.)

</PRD>

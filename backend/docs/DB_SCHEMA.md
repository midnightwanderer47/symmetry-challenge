# Articles Collection Schema

## Collection: `articles`

### Tree Structure

```
articles/{docId}
├── id: string (auto-generated)
├── author: string (required)
├── title: string (required)
├── description: string
├── url: string?
├── publishedAt: timestamp (required)
├── content: string (required)
├── thumbnailURL: string (Cloud Storage path: media/articles/{filename})
├── createdAt: timestamp (required)
├── updatedAt: timestamp? (set server-side on update, absent on initial creation)
└── isUserArticle: boolean (true for user uploads)
```

---

### Field Reference

| Field          | Type      | Required | Description                                                                 |
|----------------|-----------|----------|-----------------------------------------------------------------------------|
| `id`           | string    | ✅        | Auto-generated Firestore document ID. Stored as a field for client convenience. |
| `author`       | string    | ✅        | User ID or display name of the article author.                              |
| `title`        | string    | ✅        | Article headline. Max 200 characters.                                       |
| `description`  | string    | ❌        | Short summary of the article. Max 500 characters.                           |
| `url`          | string?   | ❌        | External source link. Null for user-uploaded articles without a source URL. |
| `publishedAt`  | timestamp | ✅        | Date and time the article was originally published.                         |
| `content`      | string    | ✅        | Full article body text. Must be non-empty.                                  |
| `thumbnailURL` | string    | ❌        | Cloud Storage path to the article thumbnail image (see format below).       |
| `createdAt`    | timestamp | ✅        | Timestamp when this Firestore document was created.                         |
| `updatedAt`    | timestamp | ❌        | Timestamp of the last update. Set server-side via `FieldValue.serverTimestamp()` on edit; absent until first update. |
| `isUserArticle`| boolean   | ✅        | `true` for user-uploaded articles; `false` for articles fetched from external APIs. |

---

### Validation Rules

| Field          | Constraint                                          |
|----------------|-----------------------------------------------------|
| `title`        | Non-empty string, max 200 characters                |
| `description`  | Optional, max 500 characters                        |
| `content`      | Non-empty string                                    |
| `url`          | Optional; if present, must be a valid URL string    |
| `publishedAt`  | Valid Firestore Timestamp, must not be in the future |
| `createdAt`    | Valid Firestore Timestamp; set server-side on write  |
| `updatedAt`    | Valid Firestore Timestamp; set server-side on update via `FieldValue.serverTimestamp()`; optional |
| `isUserArticle`| Must be explicitly set; no default assumed           |

---

### `thumbnailURL` Cloud Storage Format

The `thumbnailURL` field stores a **Cloud Storage object path** (not a full download URL). The path follows this exact format:

```
media/articles/{uuid}.{ext}
```

- `uuid` — Auto-generated UUID v4 (e.g., `550e8400-e29b-41d4-a716-446655440000`)
- `ext` — Image file extension: `jpg`, `png`, or `webp`

**Example:**
```
media/articles/550e8400-e29b-41d4-a716-446655440000.jpg
```

**Validation regex:**
```
^media/articles/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\.(jpg|png|webp)$
```

The full download URL is resolved at runtime using the Firebase Storage SDK.

---

### Recommended Indexes

| Index Type | Fields                          | Use Case                                      |
|------------|---------------------------------|-----------------------------------------------|
| Composite  | `isUserArticle` ASC + `createdAt` DESC | Paginated feed of user-uploaded articles |
| Composite  | `author` ASC + `createdAt` DESC | List articles by a specific user              |
| Single     | `createdAt` DESC                | Global feed sorted by newest first            |
| Single     | `isUserArticle`                 | Filter user vs. API-sourced articles          |

Add these to `firestore.indexes.json` before deploying.

---

### Best Practices

- **Document size**: Keep documents under 1 MB. For long articles, consider storing `content` in Cloud Storage and referencing the path.
- **Avoid full collection scans**: Always filter queries by `isUserArticle` or `author` to leverage indexes and reduce read costs.
- **Server timestamps**: Use `FieldValue.serverTimestamp()` for `createdAt` on all writes — never set this client-side.
- **Immutable fields**: Treat `id`, `createdAt`, and `isUserArticle` as write-once; do not update after creation.
- **Soft deletes**: Consider adding a `deletedAt: timestamp?` field instead of hard-deleting documents to preserve referential integrity.

---

### `ArticleEntity` Mapping

This schema maps to the Flutter `ArticleEntity` domain model:

| Firestore Field  | `ArticleEntity` Field  | Notes                                 |
|------------------|------------------------|---------------------------------------|
| `id`             | `id`                   | Document ID                           |
| `author`         | `author`               |                                       |
| `title`          | `title`                |                                       |
| `description`    | `description`          |                                       |
| `url`            | `url`                  |                                       |
| `publishedAt`    | `publishedAt`          | Stored as timestamp, exposed as string |
| `content`        | `content`              |                                       |
| `thumbnailURL`   | `thumbnailURL`         | New field — Cloud Storage path         |
| `createdAt`      | `createdAt`            | New field                             |
| `updatedAt`      | `updatedAt`            | Optional; absent until first update   |
| `isUserArticle`  | `isUserArticle`        | New field                             |

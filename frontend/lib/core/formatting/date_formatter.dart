import 'dart:ui';

import 'package:intl/intl.dart';

/// Formats an ISO 8601 [publishedAt] (or [createdAt] fallback) into a
/// locale-appropriate date + time string such as "Mar 29, 2026, 2:47 PM".
///
/// Returns the raw string unchanged when it cannot be parsed, and an empty
/// string when both inputs are null/empty.
String formatPublishedAt(
    String? publishedAt, String? createdAt, Locale locale) {
  final raw =
      (publishedAt != null && publishedAt.isNotEmpty) ? publishedAt : createdAt;

  if (raw == null || raw.isEmpty) return '';

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;

  final local = parsed.toLocal();
  final localeTag = locale.toLanguageTag();
  return DateFormat.yMMMd(localeTag).add_jm().format(local);
}

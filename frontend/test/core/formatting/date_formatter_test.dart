import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/formatting/date_formatter.dart';

void main() {
  const locale = Locale('en', 'US');

  test('formats a UTC ISO 8601 string into locale date + time', () {
    final result = formatPublishedAt('2026-03-28T18:14:00Z', null, locale);
    expect(result, contains('Mar'));
    expect(result, contains('2026'));
    expect(result, contains('28'));
  });

  test('formats ISO string with fractional seconds', () {
    final result =
        formatPublishedAt('2026-03-29T14:47:03.121977', null, locale);
    expect(result, contains('Mar'));
    expect(result, contains('2026'));
  });

  test('falls back to createdAt when publishedAt is null', () {
    final result = formatPublishedAt(null, '2025-12-25T10:00:00Z', locale);
    expect(result, contains('Dec'));
    expect(result, contains('2025'));
  });

  test('falls back to createdAt when publishedAt is empty', () {
    final result = formatPublishedAt('', '2025-06-01T08:30:00Z', locale);
    expect(result, contains('Jun'));
    expect(result, contains('2025'));
  });

  test('returns empty string when both are null', () {
    expect(formatPublishedAt(null, null, locale), '');
  });

  test('returns empty string when both are empty', () {
    expect(formatPublishedAt('', '', locale), '');
  });

  test('returns original string when unparseable', () {
    expect(formatPublishedAt('not-a-date', null, locale), 'not-a-date');
  });
}

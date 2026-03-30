import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/upload_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/upload_article_thumbnail.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/upload/article_upload_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/upload/article_upload_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/pages/upload_article/upload_article.dart';

// Mock repository used only to satisfy use case constructors in stub cubits.
class _MockRepository extends Mock implements ArticleRepository {}

class _MockUser extends Mock implements User {}

/// A cubit subclass that starts at [initialState] without calling through
/// to the real use cases.
class _SeededCubit extends ArticleUploadCubit {
  _SeededCubit(ArticleUploadState initialState)
      : super(
          UploadArticleUseCase(_MockRepository()),
          UploadArticleThumbnailUseCase(_MockRepository()),
          getCurrentUser: () => _MockUser(),
        ) {
    emit(initialState);
  }

  @override
  Future<void> upload(ArticleEntity article,
      {String? thumbnailFilePath}) async {
    // no-op: state is seeded in constructor
  }
}

/// A cubit that emits Loading → [result] when upload() is called.
class _EmittingCubit extends ArticleUploadCubit {
  final ArticleUploadState result;

  _EmittingCubit(this.result)
      : super(
          UploadArticleUseCase(_MockRepository()),
          UploadArticleThumbnailUseCase(_MockRepository()),
          getCurrentUser: () => _MockUser(),
        );

  @override
  Future<void> upload(ArticleEntity article,
      {String? thumbnailFilePath}) async {
    emit(const ArticleUploadLoading());
    await Future.delayed(Duration.zero);
    emit(result);
  }
}

/// A cubit that captures the [ArticleEntity] passed to upload().
class _CapturingCubit extends ArticleUploadCubit {
  ArticleEntity? lastArticle;

  _CapturingCubit()
      : super(
          UploadArticleUseCase(_MockRepository()),
          UploadArticleThumbnailUseCase(_MockRepository()),
          getCurrentUser: () => _MockUser(),
        );

  @override
  Future<void> upload(ArticleEntity article,
      {String? thumbnailFilePath}) async {
    lastArticle = article;
    emit(const ArticleUploadSuccess());
  }
}

final _sl = GetIt.instance;

Directory? _tempDir;

Widget _buildApp({XFile? initialThumbnail}) => MaterialApp(
      home: UploadArticleView(
        authStateStream: Stream.value(_MockUser()),
        initialThumbnail: initialThumbnail,
      ),
    );

void main() {
  setUp(() async {
    _sl.reset();
    _tempDir = await Directory.systemTemp.createTemp('upload_article_test_');
  });
  tearDown(() async {
    _sl.reset();
    if (_tempDir != null && _tempDir!.existsSync()) {
      await _tempDir!.delete(recursive: true);
    }
  });

  group('UploadArticleView – form rendering', () {
    testWidgets('shows Title, Author, Description, Content fields and button',
        (tester) async {
      _sl.registerFactory<ArticleUploadCubit>(
          () => _SeededCubit(const ArticleUploadInitial()));
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Title *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Author *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Description *'), findsOneWidget);
      expect(find.text('Content *'), findsOneWidget);
      expect(find.byKey(const Key('upload_article_content')), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Publish Article'),
          findsOneWidget);
    });
  });

  group('UploadArticleView – form validation', () {
    testWidgets('shows validation errors when submitting empty form',
        (tester) async {
      _sl.registerFactory<ArticleUploadCubit>(
          () => _SeededCubit(const ArticleUploadInitial()));
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Required'), findsWidgets);
    });

    testWidgets('shows SnackBar when all text fields filled but no thumbnail',
        (tester) async {
      _sl.registerFactory<ArticleUploadCubit>(
          () => _SeededCubit(const ArticleUploadInitial()));
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title *'), 'My Title');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Author *'), 'Jane Doe');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Description *'), 'A description');
      await tester.enterText(
          find.byKey(const Key('upload_article_content')), 'Some content here');

      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Please add a thumbnail image to publish.'),
          findsOneWidget);
    });

    testWidgets('sets publishedAt automatically on valid submit',
        (tester) async {
      final cubit = _CapturingCubit();
      _sl.registerSingleton<ArticleUploadCubit>(cubit);
      final thumbFile = File('${_tempDir!.path}/thumb.jpg');
      thumbFile.writeAsBytesSync(const [0xff, 0xd8, 0xff]);
      final thumb = XFile(thumbFile.path);

      await tester.pumpWidget(_buildApp(initialThumbnail: thumb));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title *'), 'My Title');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Author *'), 'Jane Doe');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Description *'), 'Desc');
      await tester.enterText(
          find.byKey(const Key('upload_article_content')), 'Some content here');

      final before = DateTime.now();
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(cubit.lastArticle, isNotNull);
      final parsed = DateTime.parse(cubit.lastArticle!.publishedAt!);
      expect(
          parsed.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
    });
  });

  group('UploadArticleView – loading state', () {
    testWidgets(
        'shows CircularProgressIndicator and disables button when loading',
        (tester) async {
      _sl.registerFactory<ArticleUploadCubit>(
          () => _SeededCubit(const ArticleUploadLoading()));
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
      expect(find.text('Publishing...'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });

  group('UploadArticleView – failure state', () {
    testWidgets('shows SnackBar with error message on Failure state',
        (tester) async {
      final cubit = _EmittingCubit(
          const ArticleUploadFailure('Upload failed: network error'));
      _sl.registerSingleton<ArticleUploadCubit>(cubit);

      await tester.pumpWidget(_buildApp());
      await tester.pump();

      cubit.upload(const ArticleEntity(title: 'T', author: 'A', content: 'C'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Upload failed: network error'), findsOneWidget);
    });

    testWidgets('loading overlay absent and SnackBar shown after Failure state',
        (tester) async {
      final cubit = _EmittingCubit(const ArticleUploadFailure('Network error'));
      _sl.registerSingleton<ArticleUploadCubit>(cubit);

      await tester.pumpWidget(_buildApp());
      await tester.pump();

      cubit.upload(const ArticleEntity(title: 'T', author: 'A', content: 'C'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Publishing...'), findsNothing);
      expect(find.text('Network error'), findsOneWidget);
    });
  });
}

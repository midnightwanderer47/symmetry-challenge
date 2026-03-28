import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/upload_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/upload_article_thumbnail.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/upload/article_upload_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/upload/article_upload_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/pages/upload_article/upload_article.dart';

// Mock repository used only to satisfy use case constructors in stub cubits.
class _MockRepository extends Mock implements ArticleRepository {}

ArticleUploadCubit _makeCubitWithState(ArticleUploadState initial) {
  final repo = _MockRepository();
  final cubit = ArticleUploadCubit(
    UploadArticleUseCase(repo),
    UploadArticleThumbnailUseCase(repo),
  );
  // Emit the desired initial state via a no-op subclass trick:
  // We close the cubit and return a fresh one seeded to Initial;
  // for non-Initial states we use _SeededCubit below.
  return cubit;
}

/// A cubit subclass that starts at [initialState] without calling through
/// to the real use cases.
class _SeededCubit extends ArticleUploadCubit {
  _SeededCubit(ArticleUploadState initialState)
      : super(
          UploadArticleUseCase(_MockRepository()),
          UploadArticleThumbnailUseCase(_MockRepository()),
        ) {
    emit(initialState);
  }

  @override
  Future<void> upload(ArticleEntity article, {String? thumbnailFilePath}) async {
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
        );

  @override
  Future<void> upload(ArticleEntity article, {String? thumbnailFilePath}) async {
    emit(const ArticleUploadLoading());
    await Future.delayed(Duration.zero);
    emit(result);
  }
}

final _sl = GetIt.instance;

Widget _buildApp() => const MaterialApp(home: UploadArticleView());

void main() {
  setUp(() => _sl.reset());
  tearDown(() => _sl.reset());

  group('UploadArticleView – form rendering', () {
    testWidgets('shows Title, Author, Content fields and Upload button', (tester) async {
      _sl.registerFactory<ArticleUploadCubit>(() => _SeededCubit(const ArticleUploadInitial()));
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Title *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Author *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Content *'), findsOneWidget);
      // AppBar + ElevatedButton both contain "Upload Article"; verify the button exists.
      expect(find.widgetWithText(ElevatedButton, 'Upload Article'), findsOneWidget);
    });
  });

  group('UploadArticleView – form validation', () {
    testWidgets('shows validation errors when submitting empty form', (tester) async {
      _sl.registerFactory<ArticleUploadCubit>(() => _SeededCubit(const ArticleUploadInitial()));
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Required'), findsWidgets);
    });

    testWidgets('shows SnackBar when date is missing on valid form', (tester) async {
      _sl.registerFactory<ArticleUploadCubit>(() => _SeededCubit(const ArticleUploadInitial()));
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Title *'), 'My Title');
      await tester.enterText(find.widgetWithText(TextFormField, 'Author *'), 'Jane Doe');
      await tester.enterText(find.widgetWithText(TextFormField, 'Content *'), 'Some content here');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Please select a publication date'), findsOneWidget);
    });
  });

  group('UploadArticleView – loading state', () {
    testWidgets('shows CircularProgressIndicator and disables button when loading', (tester) async {
      _sl.registerFactory<ArticleUploadCubit>(() => _SeededCubit(const ArticleUploadLoading()));
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });

  group('UploadArticleView – failure state', () {
    testWidgets('shows SnackBar with error message on Failure state', (tester) async {
      final cubit = _EmittingCubit(const ArticleUploadFailure('Upload failed: network error'));
      // Use singleton so the widget's BlocProvider gets the same instance.
      _sl.registerSingleton<ArticleUploadCubit>(cubit);

      await tester.pumpWidget(_buildApp());
      await tester.pump();

      // Trigger the state transition directly on the cubit that the widget listens to.
      cubit.upload(const ArticleEntity(title: 'T', author: 'A', content: 'C'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Upload failed: network error'), findsOneWidget);
    });
  });
}

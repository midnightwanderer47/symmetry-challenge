import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_user_articles.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/user/user_articles_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/user/user_articles_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/pages/user_articles/user_articles_screen.dart';

class _MockRepository extends Mock implements ArticleRepository {}

// Article with all force-unwrapped fields populated (ArticleWidget uses urlToImage! and publishedAt!)
const _testArticle = ArticleEntity(
  title: 'My Test Article',
  author: 'Test Author',
  description: 'A test description',
  urlToImage: 'https://example.com/image.jpg',
  publishedAt: '2024-01-01T00:00:00.000Z',
  isUserArticle: true,
);

/// Cubit that starts in [initial] and does nothing on fetchUserArticles().
class _SeededCubit extends UserArticlesCubit {
  _SeededCubit(UserArticlesState initial)
      : super(GetUserArticlesUseCase(_MockRepository())) {
    emit(initial);
  }

  @override
  Future<void> fetchUserArticles() async {}
}

/// Cubit that records calls to fetchUserArticles without doing anything.
class _SpyCubit extends UserArticlesCubit {
  int fetchCallCount = 0;

  _SpyCubit(UserArticlesState initial)
      : super(GetUserArticlesUseCase(_MockRepository())) {
    emit(initial);
  }

  @override
  Future<void> fetchUserArticles() async {
    fetchCallCount++;
  }
}

final _sl = GetIt.instance;

Widget _buildScreen() => MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == '/ArticleDetails') {
          return MaterialPageRoute(builder: (_) => const Scaffold());
        }
        return null;
      },
      home: const UserArticlesScreen(),
    );

void main() {
  setUp(() => _sl.reset());
  tearDown(() => _sl.reset());

  testWidgets('shows CupertinoActivityIndicator when state is Loading', (tester) async {
    _sl.registerFactory<UserArticlesCubit>(() => _SeededCubit(const UserArticlesLoading()));
    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
  });

  testWidgets('shows refresh icon when state is Error', (tester) async {
    _sl.registerFactory<UserArticlesCubit>(
        () => _SeededCubit(const UserArticlesError('Something went wrong')));
    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('shows "No articles yet" when Loaded with empty list', (tester) async {
    _sl.registerFactory<UserArticlesCubit>(() => _SeededCubit(const UserArticlesLoaded([])));
    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    expect(find.text('No articles yet'), findsOneWidget);
  });

  testWidgets('shows article title when Loaded with articles', (tester) async {
    _sl.registerFactory<UserArticlesCubit>(
        () => _SeededCubit(const UserArticlesLoaded([_testArticle])));
    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    expect(find.text('My Test Article'), findsOneWidget);
  });

  testWidgets('pull-to-refresh triggers fetchUserArticles', (tester) async {
    final cubit = _SpyCubit(const UserArticlesLoaded([_testArticle]));
    _sl.registerSingleton<UserArticlesCubit>(cubit);

    await tester.pumpWidget(_buildScreen());
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(cubit.fetchCallCount, greaterThanOrEqualTo(1));
  });
}

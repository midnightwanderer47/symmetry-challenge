import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/paginated_articles.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_articles_page.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_articles_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_articles_state.dart';

class MockGetArticleUseCase extends Mock implements GetArticleUseCase {}

class MockGetArticlesPageUseCase extends Mock implements GetArticlesPageUseCase {}

DioError _dioError() => DioError(
      requestOptions: RequestOptions(path: ''),
      error: Exception('fetch error'),
    );

const _apiArticle = ArticleEntity(
  title: 'API Article',
  author: 'Author A',
  isUserArticle: false,
);

const _userArticle = ArticleEntity(
  title: 'User Article',
  author: 'Author B',
  isUserArticle: true,
);

const _emptyPage = PaginatedArticles(articles: [], hasMore: false);
const _pageWithUser = PaginatedArticles(articles: [_userArticle], hasMore: false);

void main() {
  late MockGetArticleUseCase mockUseCase;
  late MockGetArticlesPageUseCase mockPageUseCase;

  setUp(() {
    mockUseCase = MockGetArticleUseCase();
    mockPageUseCase = MockGetArticlesPageUseCase();
  });

  /// Creates a cubit and waits for the constructor's auto-fetch to complete.
  Future<RemoteArticlesCubit> buildCubit() async {
    final cubit = RemoteArticlesCubit(mockUseCase, mockPageUseCase);
    await pumpEventQueue();
    return cubit;
  }

  test('initial state before auto-fetch completes is RemoteArticlesLoading',
      () {
    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess([]));
    when(() => mockPageUseCase(limit: any(named: 'limit'), startAfter: any(named: 'startAfter')))
        .thenAnswer((_) async => const DataSuccess(_emptyPage));
    final cubit = RemoteArticlesCubit(mockUseCase, mockPageUseCase);
    expect(cubit.state, const RemoteArticlesLoading());
    cubit.close();
  });

  test('emits Loaded with merged articles when fetch succeeds', () async {
    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess([_apiArticle]));
    when(() => mockPageUseCase(limit: any(named: 'limit'), startAfter: any(named: 'startAfter')))
        .thenAnswer((_) async => const DataSuccess(_pageWithUser));
    final cubit = await buildCubit();
    final state = cubit.state as RemoteArticlesLoaded;
    expect(state.articles, [_apiArticle, _userArticle]);
    expect(state.isUserArticles, true);
    cubit.close();
  });

  test('isUserArticles is false when no user articles in list', () async {
    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess([_apiArticle]));
    when(() => mockPageUseCase(limit: any(named: 'limit'), startAfter: any(named: 'startAfter')))
        .thenAnswer((_) async => const DataSuccess(_emptyPage));
    final cubit = await buildCubit();
    final state = cubit.state as RemoteArticlesLoaded;
    expect(state.isUserArticles, false);
    cubit.close();
  });

  test('emits Error when page fetch fails and news api also fails', () async {
    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => DataFailed(_dioError()));
    when(() => mockPageUseCase(limit: any(named: 'limit'), startAfter: any(named: 'startAfter')))
        .thenAnswer((_) async => DataFailed(_dioError()));
    final cubit = await buildCubit();
    expect(cubit.state, isA<RemoteArticlesError>());
    cubit.close();
  });

  test('fetchArticles emits Loading then Loaded', () async {
    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess([_apiArticle]));
    when(() => mockPageUseCase(limit: any(named: 'limit'), startAfter: any(named: 'startAfter')))
        .thenAnswer((_) async => const DataSuccess(_emptyPage));
    final cubit = await buildCubit();

    final states = <RemoteArticlesState>[];
    final subscription = cubit.stream.listen(states.add);
    await cubit.fetchArticles();
    await pumpEventQueue();
    await subscription.cancel();

    expect(states.first, const RemoteArticlesLoading());
    expect(states.last, isA<RemoteArticlesLoaded>());
    cubit.close();
  });

  test('refresh re-emits Loading then Loaded', () async {
    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess([_apiArticle]));
    when(() => mockPageUseCase(limit: any(named: 'limit'), startAfter: any(named: 'startAfter')))
        .thenAnswer((_) async => const DataSuccess(_emptyPage));
    final cubit = await buildCubit();

    final states = <RemoteArticlesState>[];
    final subscription = cubit.stream.listen(states.add);
    await cubit.refresh();
    await pumpEventQueue();
    await subscription.cancel();

    expect(states.first, const RemoteArticlesLoading());
    expect(states.last, isA<RemoteArticlesLoaded>());
    cubit.close();
  });

  test('loadMore appends articles and updates hasMore', () async {
    const firstPage = PaginatedArticles(
      articles: [_userArticle],
      hasMore: true,
      cursor: 'cursor1',
    );
    const secondPage = PaginatedArticles(articles: [_apiArticle], hasMore: false);

    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess([]));
    when(() => mockPageUseCase(limit: any(named: 'limit'), startAfter: any(named: 'startAfter')))
        .thenAnswer((_) async => const DataSuccess(firstPage));
    final cubit = await buildCubit();

    // Now set up second page response
    when(() => mockPageUseCase(limit: any(named: 'limit'), startAfter: any(named: 'startAfter')))
        .thenAnswer((_) async => const DataSuccess(secondPage));

    await cubit.loadMore();
    await pumpEventQueue();

    final state = cubit.state as RemoteArticlesLoaded;
    expect(state.articles, [_userArticle, _apiArticle]);
    expect(state.hasMore, false);
    cubit.close();
  });

  test('loadMore is no-op when hasMore is false', () async {
    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess([]));
    when(() => mockPageUseCase(limit: any(named: 'limit'), startAfter: any(named: 'startAfter')))
        .thenAnswer((_) async => const DataSuccess(_emptyPage));
    final cubit = await buildCubit();

    final states = <RemoteArticlesState>[];
    final subscription = cubit.stream.listen(states.add);
    await cubit.loadMore();
    await pumpEventQueue();
    await subscription.cancel();

    expect(states, isEmpty);
    cubit.close();
  });
}

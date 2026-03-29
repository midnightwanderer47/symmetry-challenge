import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_articles_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_articles_state.dart';

class MockGetArticleUseCase extends Mock implements GetArticleUseCase {}

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

void main() {
  late MockGetArticleUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetArticleUseCase();
  });

  /// Creates a cubit and waits for the constructor's auto-fetch to complete.
  Future<RemoteArticlesCubit> buildCubit() async {
    final cubit = RemoteArticlesCubit(mockUseCase);
    await pumpEventQueue();
    return cubit;
  }

  test('initial state before auto-fetch completes is RemoteArticlesLoading',
      () {
    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess([]));
    final cubit = RemoteArticlesCubit(mockUseCase);
    expect(cubit.state, const RemoteArticlesLoading());
    cubit.close();
  });

  test('emits Loaded with articles when fetch succeeds', () async {
    when(() => mockUseCase(params: any(named: 'params'))).thenAnswer(
        (_) async => const DataSuccess([_apiArticle, _userArticle]));
    final cubit = await buildCubit();
    expect(
      cubit.state,
      const RemoteArticlesLoaded([_apiArticle, _userArticle],
          isUserArticles: true),
    );
    cubit.close();
  });

  test('isUserArticles is false when no user articles in list', () async {
    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess([_apiArticle]));
    final cubit = await buildCubit();
    final state = cubit.state as RemoteArticlesLoaded;
    expect(state.isUserArticles, false);
    cubit.close();
  });

  test('emits Error when fetch fails', () async {
    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => DataFailed(_dioError()));
    final cubit = await buildCubit();
    expect(cubit.state, isA<RemoteArticlesError>());
    cubit.close();
  });

  test('fetchArticles emits Loading then Loaded', () async {
    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess([_apiArticle]));
    final cubit = await buildCubit();

    // State is now Loaded; listen for next fetchArticles transitions
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
}

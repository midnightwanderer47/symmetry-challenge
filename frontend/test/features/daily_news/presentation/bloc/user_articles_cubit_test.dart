import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_user_articles.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/user/user_articles_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/user/user_articles_state.dart';

class MockGetUserArticlesUseCase extends Mock
    implements GetUserArticlesUseCase {}

DioError _dioError() => DioError(
      requestOptions: RequestOptions(path: ''),
      error: Exception('fetch error'),
    );

const _article1 = ArticleEntity(
  title: 'Article 1',
  author: 'Author 1',
  isUserArticle: true,
);

const _article2 = ArticleEntity(
  title: 'Article 2',
  author: 'Author 2',
  isUserArticle: true,
);

void main() {
  late MockGetUserArticlesUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetUserArticlesUseCase();
  });

  UserArticlesCubit buildCubit() => UserArticlesCubit(mockUseCase);

  test('initial state is UserArticlesInitial', () {
    expect(buildCubit().state, const UserArticlesInitial());
  });

  test('state is Loaded with articles when fetch succeeds', () async {
    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess([_article1, _article2]));
    final cubit = buildCubit();
    await cubit.fetchUserArticles();
    expect(cubit.state, const UserArticlesLoaded([_article1, _article2]));
  });

  test('state is Loaded([]) when fetch returns empty list', () async {
    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess([]));
    final cubit = buildCubit();
    await cubit.fetchUserArticles();
    expect(cubit.state, const UserArticlesLoaded([]));
  });

  test('state is Error when fetch fails', () async {
    when(() => mockUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => DataFailed(_dioError()));
    final cubit = buildCubit();
    await cubit.fetchUserArticles();
    expect(cubit.state, isA<UserArticlesError>());
  });

  test('emits Loading before fetching', () async {
    final loadingStates = <UserArticlesState>[];
    when(() => mockUseCase(params: any(named: 'params'))).thenAnswer((_) async {
      return const DataSuccess([_article1]);
    });
    final cubit = buildCubit();
    cubit.stream.listen(loadingStates.add);
    await cubit.fetchUserArticles();
    expect(loadingStates, contains(const UserArticlesLoading()));
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/update_article.dart';

class MockArticleRepository extends Mock implements ArticleRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ArticleEntity());
  });

  late MockArticleRepository mockRepository;
  late UpdateArticleUseCase useCase;

  const validArticle = ArticleEntity(
    firestoreId: 'abc-123',
    title: 'Valid Article',
    isUserArticle: true,
  );

  const articleWithoutFirestoreId = ArticleEntity(
    title: 'No Firestore ID',
    isUserArticle: true,
  );

  setUp(() {
    mockRepository = MockArticleRepository();
    useCase = UpdateArticleUseCase(mockRepository);
  });

  group('UpdateArticleUseCase', () {
    test('delegates to repository.updateArticle with the given entity',
        () async {
      when(() => mockRepository.updateArticle(any()))
          .thenAnswer((_) async => const DataSuccess(null));

      await useCase(params: validArticle);

      verify(() => mockRepository.updateArticle(validArticle)).called(1);
    });

    test('returns DataSuccess when repository succeeds', () async {
      when(() => mockRepository.updateArticle(any()))
          .thenAnswer((_) async => const DataSuccess(null));

      final result = await useCase(params: validArticle);

      expect(result, isA<DataSuccess<void>>());
    });

    test('returns DataFailed when repository fails', () async {
      when(() => mockRepository.updateArticle(any()))
          .thenAnswer((_) async => DataFailed(DioError(
                requestOptions: RequestOptions(path: ''),
                error: 'update error',
              )));

      final result = await useCase(params: validArticle);

      expect(result, isA<DataFailed<void>>());
    });

    test('throws ArgumentError when params is null', () {
      expect(
        () => useCase(params: null),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(() => mockRepository.updateArticle(any()));
    });

    test('throws ArgumentError when article has no firestoreId', () {
      expect(
        () => useCase(params: articleWithoutFirestoreId),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(() => mockRepository.updateArticle(any()));
    });
  });
}

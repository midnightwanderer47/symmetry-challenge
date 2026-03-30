import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/firestore/firestore_article_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/local/app_database.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/news_api_service.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/storage/firebase_storage_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/repository/article_repository_impl.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';

class MockNewsApiService extends Mock implements NewsApiService {}

class MockFirestoreArticleDataSource extends Mock
    implements FirestoreArticleDataSource {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockFirebaseStorageDataSource extends Mock
    implements FirebaseStorageDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ArticleModel());
  });

  late MockNewsApiService mockNewsApiService;
  late MockFirestoreArticleDataSource mockFirestore;
  late MockAppDatabase mockDatabase;
  late MockFirebaseStorageDataSource mockStorage;
  late ArticleRepositoryImpl repository;

  const articleWithFirestoreId = ArticleEntity(
    firestoreId: 'test-id-123',
    title: 'Test Article',
    isUserArticle: true,
  );

  const articleWithoutFirestoreId = ArticleEntity(
    title: 'No ID Article',
    isUserArticle: true,
  );

  setUp(() {
    mockNewsApiService = MockNewsApiService();
    mockFirestore = MockFirestoreArticleDataSource();
    mockDatabase = MockAppDatabase();
    mockStorage = MockFirebaseStorageDataSource();
    repository = ArticleRepositoryImpl(
      mockNewsApiService,
      mockDatabase,
      mockFirestore,
      mockStorage,
    );
  });

  group('updateArticle', () {
    test('returns DataSuccess when update succeeds', () async {
      when(() => mockFirestore.updateArticle(any(), any()))
          .thenAnswer((_) async {});

      final result = await repository.updateArticle(articleWithFirestoreId);

      expect(result, isA<DataSuccess<void>>());
    });

    test('calls updateArticle on data source with correct firestoreId',
        () async {
      when(() => mockFirestore.updateArticle(any(), any()))
          .thenAnswer((_) async {});

      await repository.updateArticle(articleWithFirestoreId);

      verify(() => mockFirestore.updateArticle(
            'test-id-123',
            any(that: isA<ArticleModel>()),
          )).called(1);
    });

    test('returns DataFailed when firestoreId is null', () async {
      final result = await repository.updateArticle(articleWithoutFirestoreId);

      expect(result, isA<DataFailed<void>>());
      verifyNever(() => mockFirestore.updateArticle(any(), any()));
    });

    test('returns DataFailed when data source throws', () async {
      when(() => mockFirestore.updateArticle(any(), any()))
          .thenThrow(Exception('Firestore error'));

      final result = await repository.updateArticle(articleWithFirestoreId);

      expect(result, isA<DataFailed<void>>());
    });

    test('wraps thrown exception in DataFailed error', () async {
      final exception = Exception('update failed');
      when(() => mockFirestore.updateArticle(any(), any()))
          .thenThrow(exception);

      final result = await repository.updateArticle(articleWithFirestoreId);

      expect(result, isA<DataFailed<void>>());
      expect((result as DataFailed).error, isA<DioError>());
    });
  });
}

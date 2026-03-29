import 'dart:io';

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
import 'package:retrofit/retrofit.dart';

class MockNewsApiService extends Mock implements NewsApiService {}

class MockFirestoreArticleDataSource extends Mock
    implements FirestoreArticleDataSource {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockFirebaseStorageDataSource extends Mock
    implements FirebaseStorageDataSource {}

ArticleModel _model({
  required String title,
  String? publishedAt,
  String? createdAt,
  bool isUserArticle = false,
}) =>
    ArticleModel(
      title: title,
      publishedAt: publishedAt,
      createdAt: createdAt,
      isUserArticle: isUserArticle,
    );

HttpResponse<List<ArticleModel>> _httpResponse(
  List<ArticleModel> models, {
  int statusCode = HttpStatus.ok,
}) {
  final response = Response<dynamic>(
    data: null,
    statusCode: statusCode,
    requestOptions: RequestOptions(path: ''),
  );
  return HttpResponse(models, response);
}

DioError _dioError() => DioError(
      requestOptions: RequestOptions(path: ''),
      error: Exception('network error'),
    );

void main() {
  late MockNewsApiService mockNewsApiService;
  late MockFirestoreArticleDataSource mockFirestore;
  late MockAppDatabase mockDatabase;
  late MockFirebaseStorageDataSource mockStorage;
  late ArticleRepositoryImpl repository;

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

  group('getNewsArticles', () {
    test('returns merged list when both sources succeed', () async {
      final firestoreModels = [
        _model(title: 'Firestore Article', isUserArticle: true),
      ];
      final newsApiModels = [
        _model(title: 'NewsAPI Article', isUserArticle: false),
      ];

      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => firestoreModels);
      when(() => mockNewsApiService.getNewsArticles(
            apiKey: any(named: 'apiKey'),
            country: any(named: 'country'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => _httpResponse(newsApiModels));

      final result = await repository.getNewsArticles();

      expect(result, isA<DataSuccess<List<ArticleEntity>>>());
      expect(result.data!.length, 2);
    });

    test('deduplicates by title, preferring Firestore version', () async {
      final firestoreModels = [
        _model(title: 'Duplicate Title', isUserArticle: true),
      ];
      final newsApiModels = [
        _model(title: 'Duplicate Title', isUserArticle: false),
      ];

      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => firestoreModels);
      when(() => mockNewsApiService.getNewsArticles(
            apiKey: any(named: 'apiKey'),
            country: any(named: 'country'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => _httpResponse(newsApiModels));

      final result = await repository.getNewsArticles();

      expect(result.data!.length, 1);
      expect(result.data!.first.isUserArticle, isTrue);
    });

    test('deduplication is case-insensitive and trims whitespace', () async {
      final firestoreModels = [
        _model(title: '  Hello World  ', isUserArticle: true),
      ];
      final newsApiModels = [
        _model(title: 'hello world', isUserArticle: false),
      ];

      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => firestoreModels);
      when(() => mockNewsApiService.getNewsArticles(
            apiKey: any(named: 'apiKey'),
            country: any(named: 'country'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => _httpResponse(newsApiModels));

      final result = await repository.getNewsArticles();

      expect(result.data!.length, 1);
      expect(result.data!.first.isUserArticle, isTrue);
    });

    test('sorts by publishedAt descending', () async {
      final newsApiModels = [
        _model(title: 'Old Article', publishedAt: '2024-01-01'),
        _model(title: 'New Article', publishedAt: '2024-06-01'),
      ];

      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => []);
      when(() => mockNewsApiService.getNewsArticles(
            apiKey: any(named: 'apiKey'),
            country: any(named: 'country'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => _httpResponse(newsApiModels));

      final result = await repository.getNewsArticles();

      expect(result.data!.first.title, 'New Article');
      expect(result.data!.last.title, 'Old Article');
    });

    test('falls back to createdAt when publishedAt is null', () async {
      final newsApiModels = [
        _model(title: 'No Published Date', publishedAt: null, createdAt: '2024-03-01'),
        _model(title: 'Recent Article', publishedAt: '2024-05-01'),
      ];

      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => []);
      when(() => mockNewsApiService.getNewsArticles(
            apiKey: any(named: 'apiKey'),
            country: any(named: 'country'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => _httpResponse(newsApiModels));

      final result = await repository.getNewsArticles();

      expect(result.data!.first.title, 'Recent Article');
    });

    test('returns DataSuccess with NewsAPI articles when Firestore fails', () async {
      final newsApiModels = [
        _model(title: 'NewsAPI Article'),
      ];

      when(() => mockFirestore.getUserArticles())
          .thenThrow(Exception('Firestore error'));
      when(() => mockNewsApiService.getNewsArticles(
            apiKey: any(named: 'apiKey'),
            country: any(named: 'country'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => _httpResponse(newsApiModels));

      final result = await repository.getNewsArticles();

      expect(result, isA<DataSuccess<List<ArticleEntity>>>());
      expect(result.data!.length, 1);
      expect(result.data!.first.title, 'NewsAPI Article');
    });

    test('returns DataSuccess with Firestore articles when NewsAPI fails', () async {
      final firestoreModels = [
        _model(title: 'Firestore Article', isUserArticle: true),
      ];

      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => firestoreModels);
      when(() => mockNewsApiService.getNewsArticles(
            apiKey: any(named: 'apiKey'),
            country: any(named: 'country'),
            category: any(named: 'category'),
          )).thenThrow(_dioError());

      final result = await repository.getNewsArticles();

      expect(result, isA<DataSuccess<List<ArticleEntity>>>());
      expect(result.data!.length, 1);
      expect(result.data!.first.isUserArticle, isTrue);
    });

    test('returns DataFailed when both sources fail', () async {
      when(() => mockFirestore.getUserArticles())
          .thenThrow(Exception('Firestore error'));
      when(() => mockNewsApiService.getNewsArticles(
            apiKey: any(named: 'apiKey'),
            country: any(named: 'country'),
            category: any(named: 'category'),
          )).thenThrow(_dioError());

      final result = await repository.getNewsArticles();

      expect(result, isA<DataFailed<List<ArticleEntity>>>());
    });

    test('isUserArticle is false for NewsAPI articles', () async {
      final newsApiModels = [
        _model(title: 'API Article', isUserArticle: false),
      ];

      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => []);
      when(() => mockNewsApiService.getNewsArticles(
            apiKey: any(named: 'apiKey'),
            country: any(named: 'country'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => _httpResponse(newsApiModels));

      final result = await repository.getNewsArticles();

      expect(result.data!.first.isUserArticle, isFalse);
    });

    test('isUserArticle is true for Firestore articles', () async {
      final firestoreModels = [
        _model(title: 'User Article', isUserArticle: true),
      ];

      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => firestoreModels);
      when(() => mockNewsApiService.getNewsArticles(
            apiKey: any(named: 'apiKey'),
            country: any(named: 'country'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => _httpResponse([]));

      final result = await repository.getNewsArticles();

      expect(result.data!.first.isUserArticle, isTrue);
    });

    test('returns empty list when both sources return empty', () async {
      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => []);
      when(() => mockNewsApiService.getNewsArticles(
            apiKey: any(named: 'apiKey'),
            country: any(named: 'country'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => _httpResponse([]));

      final result = await repository.getNewsArticles();

      expect(result, isA<DataSuccess<List<ArticleEntity>>>());
      expect(result.data, isEmpty);
    });
  });

  group('searchArticles', () {
    setUp(() {
      // Default stubs for getNewsArticles (used when query is empty)
      when(() => mockFirestore.getUserArticles()).thenAnswer((_) async => []);
      when(() => mockNewsApiService.getNewsArticles(
            apiKey: any(named: 'apiKey'),
            country: any(named: 'country'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => _httpResponse([]));
    });

    test('empty query delegates to getNewsArticles', () async {
      final newsApiModels = [_model(title: 'Some Article')];
      when(() => mockNewsApiService.getNewsArticles(
            apiKey: any(named: 'apiKey'),
            country: any(named: 'country'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => _httpResponse(newsApiModels));

      final result = await repository.searchArticles('');

      expect(result, isA<DataSuccess<List<ArticleEntity>>>());
      expect(result.data!.length, 1);
    });

    test('filters Firestore articles by title case-insensitively', () async {
      final firestoreModels = [
        _model(title: 'Flutter News', isUserArticle: true),
        _model(title: 'Dart Programming', isUserArticle: true),
      ];
      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => firestoreModels);
      when(() => mockNewsApiService.searchNewsArticles(
            apiKey: any(named: 'apiKey'),
            q: any(named: 'q'),
          )).thenAnswer((_) async => _httpResponse([]));

      final resultFuture = repository.searchArticles('flutter');
      await Future.delayed(const Duration(milliseconds: 450));
      final result = await resultFuture;

      expect(result, isA<DataSuccess<List<ArticleEntity>>>());
      expect(result.data!.length, 1);
      expect(result.data!.first.title, 'Flutter News');
    });

    test('filters Firestore articles by description', () async {
      final firestoreModelsWithDesc = [
        const ArticleModel(
          title: 'Tech Article',
          description: 'All about Flutter widgets',
          isUserArticle: true,
        ),
      ];
      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => firestoreModelsWithDesc);
      when(() => mockNewsApiService.searchNewsArticles(
            apiKey: any(named: 'apiKey'),
            q: any(named: 'q'),
          )).thenAnswer((_) async => _httpResponse([]));

      final resultFuture = repository.searchArticles('flutter');
      await Future.delayed(const Duration(milliseconds: 450));
      final result = await resultFuture;

      expect(result.data!.length, 1);
      expect(result.data!.first.title, 'Tech Article');
    });

    test('matches title with punctuation between query words', () async {
      final firestoreModels = [
        _model(title: 'Article: About Flutter', isUserArticle: true),
        _model(title: 'Unrelated Post', isUserArticle: true),
      ];
      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => firestoreModels);
      when(() => mockNewsApiService.searchNewsArticles(
            apiKey: any(named: 'apiKey'),
            q: any(named: 'q'),
          )).thenAnswer((_) async => _httpResponse([]));

      final resultFuture = repository.searchArticles('Article About');
      await Future.delayed(const Duration(milliseconds: 450));
      final result = await resultFuture;

      expect(result.data!.length, 1);
      expect(result.data!.first.title, 'Article: About Flutter');
    });

    test('matches title with em-dash and extra spaces between words', () async {
      final firestoreModels = [
        _model(title: 'Article — About  Something', isUserArticle: true),
      ];
      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => firestoreModels);
      when(() => mockNewsApiService.searchNewsArticles(
            apiKey: any(named: 'apiKey'),
            q: any(named: 'q'),
          )).thenAnswer((_) async => _httpResponse([]));

      final resultFuture = repository.searchArticles('article about');
      await Future.delayed(const Duration(milliseconds: 450));
      final result = await resultFuture;

      expect(result.data!.length, 1);
    });

    test('matches when query words appear in different order in title', () async {
      final firestoreModels = [
        _model(title: 'About the Article', isUserArticle: true),
      ];
      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => firestoreModels);
      when(() => mockNewsApiService.searchNewsArticles(
            apiKey: any(named: 'apiKey'),
            q: any(named: 'q'),
          )).thenAnswer((_) async => _httpResponse([]));

      final resultFuture = repository.searchArticles('Article About');
      await Future.delayed(const Duration(milliseconds: 450));
      final result = await resultFuture;

      expect(result.data!.length, 1);
    });

    test('passes raw (not pre-encoded) query to NewsAPI', () async {
      final newsApiModels = [_model(title: 'Search Result')];
      when(() => mockFirestore.getUserArticles()).thenAnswer((_) async => []);
      when(() => mockNewsApiService.searchNewsArticles(
            apiKey: any(named: 'apiKey'),
            q: any(named: 'q'),
          )).thenAnswer((_) async => _httpResponse(newsApiModels));

      final resultFuture = repository.searchArticles('dart news');
      await Future.delayed(const Duration(milliseconds: 450));
      final result = await resultFuture;

      verify(() => mockNewsApiService.searchNewsArticles(
            apiKey: any(named: 'apiKey'),
            q: 'dart news',
          )).called(1);
      expect(result.data!.length, 1);
    });

    test('merges and deduplicates results from both sources', () async {
      final firestoreModels = [
        _model(title: 'Shared Title', isUserArticle: true),
      ];
      final newsApiModels = [
        _model(title: 'Shared Title', isUserArticle: false),
        _model(title: 'Unique API Article'),
      ];
      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => firestoreModels);
      when(() => mockNewsApiService.searchNewsArticles(
            apiKey: any(named: 'apiKey'),
            q: any(named: 'q'),
          )).thenAnswer((_) async => _httpResponse(newsApiModels));

      final resultFuture = repository.searchArticles('shared');
      await Future.delayed(const Duration(milliseconds: 450));
      final result = await resultFuture;

      expect(result.data!.length, 2);
      final sharedArticle = result.data!.firstWhere((a) => a.title == 'Shared Title');
      expect(sharedArticle.isUserArticle, isTrue);
    });

    test('returns empty list when no matches found', () async {
      final firestoreModels = [_model(title: 'Unrelated Article', isUserArticle: true)];
      when(() => mockFirestore.getUserArticles())
          .thenAnswer((_) async => firestoreModels);
      when(() => mockNewsApiService.searchNewsArticles(
            apiKey: any(named: 'apiKey'),
            q: any(named: 'q'),
          )).thenAnswer((_) async => _httpResponse([]));

      final resultFuture = repository.searchArticles('zzznomatch');
      await Future.delayed(const Duration(milliseconds: 450));
      final result = await resultFuture;

      expect(result, isA<DataSuccess<List<ArticleEntity>>>());
      expect(result.data, isEmpty);
    });

    test('returns DataFailed when both sources fail', () async {
      when(() => mockFirestore.getUserArticles())
          .thenThrow(Exception('Firestore error'));
      when(() => mockNewsApiService.searchNewsArticles(
            apiKey: any(named: 'apiKey'),
            q: any(named: 'q'),
          )).thenThrow(_dioError());

      final resultFuture = repository.searchArticles('flutter');
      await Future.delayed(const Duration(milliseconds: 450));
      final result = await resultFuture;

      expect(result, isA<DataFailed<List<ArticleEntity>>>());
    });

    test('debounce: rapid calls result in only one NewsAPI call', () async {
      when(() => mockFirestore.getUserArticles()).thenAnswer((_) async => []);
      when(() => mockNewsApiService.searchNewsArticles(
            apiKey: any(named: 'apiKey'),
            q: any(named: 'q'),
          )).thenAnswer((_) async => _httpResponse([]));

      // Fire 3 calls rapidly, only the last one should execute
      repository.searchArticles('fl');
      repository.searchArticles('flu');
      final lastFuture = repository.searchArticles('flutter');

      await Future.delayed(const Duration(milliseconds: 450));
      await lastFuture;

      verify(() => mockNewsApiService.searchNewsArticles(
            apiKey: any(named: 'apiKey'),
            q: any(named: 'q'),
          )).called(1);
    });
  });
}

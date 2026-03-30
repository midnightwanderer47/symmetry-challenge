import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:news_app_clean_architecture/core/constants/constants.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/firestore/firestore_article_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/local/app_database.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/storage/firebase_storage_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';

import '../data_sources/remote/news_api_service.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final NewsApiService _newsApiService;
  final AppDatabase _appDatabase;
  final FirestoreArticleDataSource _firestoreDataSource;
  final FirebaseStorageDataSource _storageDataSource;

  Timer? _debounceTimer;

  ArticleRepositoryImpl(
    this._newsApiService,
    this._appDatabase,
    this._firestoreDataSource,
    this._storageDataSource,
  );

  @override
  Future<DataState<List<ArticleEntity>>> getNewsArticles() async {
    List<ArticleEntity>? firestoreResult;
    List<ArticleEntity>? newsApiResult;
    Object? firestoreError;
    Object? newsApiError;

    await Future.wait([
      Future(() async {
        try {
          firestoreResult = await _fetchFirestoreArticles();
        } catch (e) {
          firestoreError = e;
        }
      }),
      Future(() async {
        try {
          newsApiResult = await _fetchNewsApiArticles();
        } catch (e) {
          newsApiError = e;
        }
      }),
    ]);

    if (firestoreError != null && newsApiError != null) {
      return DataFailed(DioError(
        error: newsApiError,
        requestOptions: RequestOptions(path: ''),
      ));
    }

    return DataSuccess(_mergeAndSortArticles(
      firestoreResult ?? [],
      newsApiResult ?? [],
    ));
  }

  @override
  Future<DataState<List<ArticleEntity>>> searchArticles(String query) {
    if (query.trim().isEmpty) return getNewsArticles();

    final completer = Completer<DataState<List<ArticleEntity>>>();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      List<ArticleEntity>? firestoreResult;
      List<ArticleEntity>? newsApiResult;
      Object? firestoreError;
      Object? newsApiError;

      final queryTokens = _tokenize(query);

      await Future.wait([
        Future(() async {
          try {
            final all = await _fetchFirestoreArticles();
            firestoreResult = all.where((a) {
              return _matchesAllTokens(a.title, queryTokens) ||
                  _matchesAllTokens(a.description, queryTokens);
            }).toList();
          } catch (e) {
            firestoreError = e;
          }
        }),
        Future(() async {
          try {
            final httpResponse = await _newsApiService.searchNewsArticles(
              apiKey: newsAPIKey,
              q: query.trim(),
            );
            if (httpResponse.response.statusCode == HttpStatus.ok) {
              newsApiResult =
                  httpResponse.data.map((m) => m.toEntity()).toList();
            } else {
              throw DioError(
                error: httpResponse.response.statusMessage,
                response: httpResponse.response,
                type: DioErrorType.response,
                requestOptions: httpResponse.response.requestOptions,
              );
            }
          } catch (e) {
            newsApiError = e;
          }
        }),
      ]);

      if (firestoreError != null && newsApiError != null) {
        completer.complete(DataFailed(DioError(
          error: newsApiError,
          requestOptions: RequestOptions(path: ''),
        )));
        return;
      }

      completer.complete(DataSuccess(_mergeAndSortArticles(
        firestoreResult ?? [],
        newsApiResult ?? [],
      )));
    });

    return completer.future;
  }

  static final _nonAlphaNumeric = RegExp(r'[^a-z0-9]+');

  static List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(_nonAlphaNumeric, ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  static bool _matchesAllTokens(String? text, List<String> tokens) {
    if (text == null || tokens.isEmpty) return false;
    final normalized = text.toLowerCase().replaceAll(_nonAlphaNumeric, ' ');
    return tokens.every((t) => normalized.contains(t));
  }

  Future<List<ArticleEntity>> _fetchFirestoreArticles() async {
    final models = await _firestoreDataSource.getUserArticles();
    return models.map((m) => m.toEntity()).toList();
  }

  Future<List<ArticleEntity>> _fetchNewsApiArticles() async {
    final httpResponse = await _newsApiService.getNewsArticles(
      apiKey: newsAPIKey,
      country: countryQuery,
      category: categoryQuery,
    );
    if (httpResponse.response.statusCode == HttpStatus.ok) {
      return httpResponse.data.map((m) => m.toEntity()).toList();
    }
    throw DioError(
      error: httpResponse.response.statusMessage,
      response: httpResponse.response,
      type: DioErrorType.response,
      requestOptions: httpResponse.response.requestOptions,
    );
  }

  List<ArticleEntity> _mergeAndSortArticles(
    List<ArticleEntity> firestoreArticles,
    List<ArticleEntity> newsApiArticles,
  ) {
    final Map<String, ArticleEntity> merged = {};
    for (final a in newsApiArticles) {
      final key = (a.title ?? '').toLowerCase().trim();
      if (key.isNotEmpty) merged[key] = a;
    }
    for (final a in firestoreArticles) {
      final key = (a.title ?? '').toLowerCase().trim();
      if (key.isNotEmpty) merged[key] = a;
    }
    final list = merged.values.toList()
      ..sort((a, b) {
        final aDate = a.publishedAt ?? a.createdAt ?? '';
        final bDate = b.publishedAt ?? b.createdAt ?? '';
        return bDate.compareTo(aDate);
      });
    return list;
  }

  @override
  Future<List<ArticleModel>> getSavedArticles() async {
    return _appDatabase.articleDAO.getArticles();
  }

  @override
  Future<void> removeArticle(ArticleEntity article) {
    return _appDatabase.articleDAO
        .deleteArticle(ArticleModel.fromEntity(article));
  }

  @override
  Future<void> saveArticle(ArticleEntity article) {
    return _appDatabase.articleDAO
        .insertArticle(ArticleModel.fromEntity(article));
  }

  @override
  Future<DataState<void>> uploadArticle(ArticleEntity article) async {
    try {
      await _firestoreDataSource
          .uploadArticle(ArticleModel.fromEntity(article));
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(DioError(
        error: e,
        requestOptions: RequestOptions(path: ''),
      ));
    }
  }

  @override
  Future<DataState<String>> uploadArticleThumbnail(String filePath) async {
    try {
      final url = await _storageDataSource.uploadThumbnail(filePath);
      return DataSuccess(url);
    } catch (e) {
      return DataFailed(DioError(
        error: e,
        requestOptions: RequestOptions(path: ''),
      ));
    }
  }

  @override
  Future<DataState<List<ArticleEntity>>> getUserArticles() async {
    try {
      final models = await _firestoreDataSource.getUserArticles();
      return DataSuccess(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return DataFailed(DioError(
        error: e,
        requestOptions: RequestOptions(path: ''),
      ));
    }
  }

  @override
  Future<DataState<void>> deleteArticle(String firestoreId) async {
    try {
      await _firestoreDataSource.deleteArticle(firestoreId);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(DioError(
        error: e,
        requestOptions: RequestOptions(path: ''),
      ));
    }
  }

  @override
  Future<DataState<void>> updateArticle(ArticleEntity article) async {
    if (article.firestoreId == null) {
      return DataFailed(DioError(
        error: 'Article firestoreId is required',
        requestOptions: RequestOptions(path: ''),
      ));
    }
    try {
      final articleModel = ArticleModel.fromEntity(article);
      await _firestoreDataSource.updateArticle(
          article.firestoreId!, articleModel);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(DioError(
        error: e,
        requestOptions: RequestOptions(path: ''),
      ));
    }
  }
}

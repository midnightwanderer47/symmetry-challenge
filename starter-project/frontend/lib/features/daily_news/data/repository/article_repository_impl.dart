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

  ArticleRepositoryImpl(
    this._newsApiService,
    this._appDatabase,
    this._firestoreDataSource,
    this._storageDataSource,
  );
  
  @override
  Future<DataState<List<ArticleModel>>> getNewsArticles() async {
   try {
    final httpResponse = await _newsApiService.getNewsArticles(
      apiKey:newsAPIKey,
      country:countryQuery,
      category:categoryQuery,
    );

    if (httpResponse.response.statusCode == HttpStatus.ok) {
      return DataSuccess(httpResponse.data);
    } else {
      return DataFailed(
        DioError(
          error: httpResponse.response.statusMessage,
          response: httpResponse.response,
          type: DioErrorType.response,
          requestOptions: httpResponse.response.requestOptions
        )
      );
    }
   } on DioError catch(e){
    return DataFailed(e);
   }
  }

  @override
  Future<List<ArticleModel>> getSavedArticles() async {
    return _appDatabase.articleDAO.getArticles();
  }

  @override
  Future<void> removeArticle(ArticleEntity article) {
    return _appDatabase.articleDAO.deleteArticle(ArticleModel.fromEntity(article));
  }

  @override
  Future<void> saveArticle(ArticleEntity article) {
    return _appDatabase.articleDAO.insertArticle(ArticleModel.fromEntity(article));
  }

  @override
  Future<DataState<void>> uploadArticle(ArticleEntity article) async {
    try {
      await _firestoreDataSource.uploadArticle(ArticleModel.fromEntity(article));
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
}
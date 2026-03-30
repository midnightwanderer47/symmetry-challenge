import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';

abstract class ArticleRepository {
  // API methods
  Future<DataState<List<ArticleEntity>>> getNewsArticles();

  Future<DataState<List<ArticleEntity>>> searchArticles(String query);

  // Database methods
  Future<List<ArticleEntity>> getSavedArticles();

  Future<void> saveArticle(ArticleEntity article);

  Future<void> removeArticle(ArticleEntity article);

  // Firebase methods
  Future<DataState<void>> uploadArticle(ArticleEntity article);

  Future<DataState<String>> uploadArticleThumbnail(String filePath);

  Future<DataState<List<ArticleEntity>>> getUserArticles();

  Future<DataState<void>> deleteArticle(String firestoreId);

  Future<DataState<void>> updateArticle(ArticleEntity article);
}

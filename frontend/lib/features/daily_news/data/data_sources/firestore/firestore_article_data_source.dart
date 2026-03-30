import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';

abstract class FirestoreArticleDataSource {
  Future<void> uploadArticle(ArticleModel article);
  Future<List<ArticleModel>> getUserArticles();
  Future<void> deleteArticle(String firestoreId);
  Future<void> updateArticle(String firestoreId, ArticleModel patch);
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/paginated_articles_result.dart';

abstract class FirestoreArticleDataSource {
  Future<void> uploadArticle(ArticleModel article);
  Future<List<ArticleModel>> getUserArticles();

  /// All user-submitted articles (any author), for feed/search merge with News API.
  Future<List<ArticleModel>> getCommunityArticles();
  Future<PaginatedArticlesResult> getUserArticlesPage({
    required int limit,
    DocumentSnapshot? startAfter,
  });
  Future<void> deleteArticle(String firestoreId);
  Future<void> updateArticle(String firestoreId, ArticleModel patch);
}

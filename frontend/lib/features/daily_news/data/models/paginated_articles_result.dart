import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';

class PaginatedArticlesResult {
  final List<ArticleModel> articles;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PaginatedArticlesResult({
    required this.articles,
    this.lastDocument,
    required this.hasMore,
  });
}

import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';

class PaginatedArticles {
  final List<ArticleEntity> articles;
  final bool hasMore;
  final Object?
      cursor; // opaque cursor – typed as Object? to avoid Firestore dependency in domain

  const PaginatedArticles({
    required this.articles,
    required this.hasMore,
    this.cursor,
  });
}

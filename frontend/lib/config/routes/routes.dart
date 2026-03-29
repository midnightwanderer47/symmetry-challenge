import 'package:flutter/material.dart';

import '../../features/daily_news/domain/entities/article.dart';
import '../../features/daily_news/presentation/pages/article_detail/article_detail.dart';
import '../../features/daily_news/presentation/pages/main/main_screen.dart';
import '../../features/daily_news/presentation/pages/saved_article/saved_article.dart';
import '../../features/daily_news/presentation/pages/upload_article/upload_article.dart';
import '../../features/daily_news/presentation/pages/search/search_screen.dart';
import '../../features/daily_news/presentation/pages/user_articles/user_articles_screen.dart';

class AppRoutes {
  static const String homeRoute = '/';
  static const String articleDetailsRoute = '/ArticleDetails';
  static const String savedArticlesRoute = '/SavedArticles';
  static const String uploadArticleRoute = '/UploadArticle';
  static const String userArticlesRoute = '/UserArticles';
  static const String searchRoute = '/Search';

  static Route onGenerateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case homeRoute:
        return _materialRoute(const MainScreen());

      case articleDetailsRoute:
        return _materialRoute(
            ArticleDetailsView(article: settings.arguments as ArticleEntity));

      case savedArticlesRoute:
        return _materialRoute(const SavedArticles());

      case uploadArticleRoute:
        return _materialRoute(const UploadArticleView());

      case userArticlesRoute:
        return _materialRoute(const UserArticlesScreen());

      case searchRoute:
        final feed = settings.arguments is List<ArticleEntity>
            ? settings.arguments as List<ArticleEntity>
            : <ArticleEntity>[];
        return _materialRoute(SearchScreen(feedSnapshot: feed));

      default:
        return _materialRoute(const MainScreen());
    }
  }

  static Route<dynamic> _materialRoute(Widget view) {
    return MaterialPageRoute(builder: (_) => view);
  }
}

import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';

abstract class RemoteArticlesState extends Equatable {
  const RemoteArticlesState();

  @override
  List<Object> get props => [];
}

class RemoteArticlesLoading extends RemoteArticlesState {
  const RemoteArticlesLoading();
}

class RemoteArticlesLoaded extends RemoteArticlesState {
  final List<ArticleEntity> articles;
  final bool isUserArticles;
  final bool hasMore;
  final Object? cursor;
  final bool isLoadingMore;

  const RemoteArticlesLoaded(
    this.articles, {
    this.isUserArticles = false,
    this.hasMore = false,
    this.cursor,
    this.isLoadingMore = false,
  });

  RemoteArticlesLoaded copyWith({
    List<ArticleEntity>? articles,
    bool? isUserArticles,
    bool? hasMore,
    Object? cursor,
    bool? isLoadingMore,
  }) {
    return RemoteArticlesLoaded(
      articles ?? this.articles,
      isUserArticles: isUserArticles ?? this.isUserArticles,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object> get props => [articles, isUserArticles, hasMore, isLoadingMore];
}

class RemoteArticlesError extends RemoteArticlesState {
  final String message;

  const RemoteArticlesError(this.message);

  @override
  List<Object> get props => [message];
}

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

  const RemoteArticlesLoaded(this.articles, {this.isUserArticles = false});

  @override
  List<Object> get props => [articles, isUserArticles];
}

class RemoteArticlesError extends RemoteArticlesState {
  final String message;

  const RemoteArticlesError(this.message);

  @override
  List<Object> get props => [message];
}

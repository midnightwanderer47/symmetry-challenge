import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';

abstract class UserArticlesState extends Equatable {
  const UserArticlesState();

  @override
  List<Object> get props => [];
}

class UserArticlesInitial extends UserArticlesState {
  const UserArticlesInitial();
}

class UserArticlesLoading extends UserArticlesState {
  const UserArticlesLoading();
}

class UserArticlesLoaded extends UserArticlesState {
  final List<ArticleEntity> articles;

  const UserArticlesLoaded(this.articles);

  @override
  List<Object> get props => [articles];
}

class UserArticlesError extends UserArticlesState {
  final String message;

  const UserArticlesError(this.message);

  @override
  List<Object> get props => [message];
}

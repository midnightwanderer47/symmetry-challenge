import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';

abstract class SearchArticlesState extends Equatable {
  const SearchArticlesState();

  @override
  List<Object> get props => [];
}

class SearchArticlesInitial extends SearchArticlesState {
  const SearchArticlesInitial();
}

class SearchArticlesLoading extends SearchArticlesState {
  const SearchArticlesLoading();
}

class SearchArticlesLoaded extends SearchArticlesState {
  final List<ArticleEntity> articles;

  const SearchArticlesLoaded(this.articles);

  @override
  List<Object> get props => [articles];
}

class SearchArticlesEmpty extends SearchArticlesState {
  const SearchArticlesEmpty();
}

class SearchArticlesError extends SearchArticlesState {
  final String message;

  const SearchArticlesError(this.message);

  @override
  List<Object> get props => [message];
}

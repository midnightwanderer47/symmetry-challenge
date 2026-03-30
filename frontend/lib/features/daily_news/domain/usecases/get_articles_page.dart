import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/paginated_articles.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';

class GetArticlesPageUseCase {
  final ArticleRepository _repository;

  GetArticlesPageUseCase(this._repository);

  Future<DataState<PaginatedArticles>> call({
    required int limit,
    Object? startAfter,
  }) {
    return _repository.getArticlesPage(limit: limit, startAfter: startAfter);
  }
}

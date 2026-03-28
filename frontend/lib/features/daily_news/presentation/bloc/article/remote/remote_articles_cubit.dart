import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_articles_state.dart';

class RemoteArticlesCubit extends Cubit<RemoteArticlesState> {
  final GetArticleUseCase _getArticleUseCase;

  RemoteArticlesCubit(this._getArticleUseCase) : super(const RemoteArticlesLoading()) {
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    emit(const RemoteArticlesLoading());
    final result = await _getArticleUseCase();
    if (result is DataSuccess && result.data != null && result.data!.isNotEmpty) {
      final articles = result.data!;
      final hasUserArticles = articles.any((a) => a.isUserArticle);
      emit(RemoteArticlesLoaded(articles, isUserArticles: hasUserArticles));
    } else if (result is DataFailed) {
      emit(RemoteArticlesError(result.error?.error?.toString() ?? 'Failed to load articles'));
    }
  }

  Future<void> refresh() => fetchArticles();
}

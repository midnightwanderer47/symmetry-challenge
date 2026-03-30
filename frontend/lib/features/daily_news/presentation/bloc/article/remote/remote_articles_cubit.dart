import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_articles_page.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_articles_state.dart';

class RemoteArticlesCubit extends Cubit<RemoteArticlesState> {
  final GetArticleUseCase _getArticleUseCase;
  final GetArticlesPageUseCase _getArticlesPageUseCase;

  List<ArticleEntity> _cachedNewsApiArticles = [];

  RemoteArticlesCubit(this._getArticleUseCase, this._getArticlesPageUseCase)
      : super(const RemoteArticlesLoading()) {
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    emit(const RemoteArticlesLoading());
    _cachedNewsApiArticles = [];

    final newsResult = await _getArticleUseCase();
    if (newsResult is DataSuccess && newsResult.data != null) {
      _cachedNewsApiArticles = newsResult.data!;
    }

    final pageResult = await _getArticlesPageUseCase(limit: 20);
    if (pageResult is DataSuccess && pageResult.data != null) {
      final page = pageResult.data!;
      final merged = [..._cachedNewsApiArticles, ...page.articles];
      final hasUserArticles = merged.any((a) => a.isUserArticle);
      emit(RemoteArticlesLoaded(
        merged,
        isUserArticles: hasUserArticles,
        hasMore: page.hasMore,
        cursor: page.cursor,
      ));
    } else if (pageResult is DataFailed) {
      if (_cachedNewsApiArticles.isNotEmpty) {
        emit(RemoteArticlesLoaded(
          _cachedNewsApiArticles,
          hasMore: false,
        ));
      } else {
        emit(RemoteArticlesError(
            pageResult.error?.error?.toString() ?? 'Failed to load articles'));
      }
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! RemoteArticlesLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final pageResult = await _getArticlesPageUseCase(
      limit: 20,
      startAfter: current.cursor,
    );

    if (pageResult is DataSuccess && pageResult.data != null) {
      final page = pageResult.data!;
      final merged = [...current.articles, ...page.articles];
      final hasUserArticles = merged.any((a) => a.isUserArticle);
      emit(RemoteArticlesLoaded(
        merged,
        isUserArticles: hasUserArticles,
        hasMore: page.hasMore,
        cursor: page.cursor,
        isLoadingMore: false,
      ));
    } else {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() => fetchArticles();
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/search_articles.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/search/search_articles_state.dart';

class SearchArticlesCubit extends Cubit<SearchArticlesState> {
  final SearchArticlesUseCase _searchArticlesUseCase;
  Timer? _debounce;

  SearchArticlesCubit(this._searchArticlesUseCase) : super(const SearchArticlesInitial());

  void queryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      emit(const SearchArticlesInitial());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      emit(const SearchArticlesLoading());
      final result = await _searchArticlesUseCase(params: query.trim());
      if (result is DataSuccess && result.data != null) {
        if (result.data!.isEmpty) {
          emit(const SearchArticlesEmpty());
        } else {
          emit(SearchArticlesLoaded(result.data!));
        }
      } else if (result is DataFailed) {
        emit(SearchArticlesError(result.error?.error?.toString() ?? 'Search failed'));
      }
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_user_articles.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/user/user_articles_state.dart';

class UserArticlesCubit extends Cubit<UserArticlesState> {
  final GetUserArticlesUseCase _getUserArticlesUseCase;

  UserArticlesCubit(this._getUserArticlesUseCase)
      : super(const UserArticlesInitial());

  Future<void> fetchUserArticles() async {
    emit(const UserArticlesLoading());
    final result = await _getUserArticlesUseCase();
    if (result is DataSuccess && result.data != null) {
      emit(UserArticlesLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(UserArticlesError(
          result.error?.error?.toString() ?? 'Failed to load articles'));
    }
  }
}

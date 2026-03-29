import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/delete_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/delete/delete_article_state.dart';

class DeleteArticleCubit extends Cubit<DeleteArticleState> {
  final DeleteArticleUseCase _deleteArticleUseCase;

  DeleteArticleCubit(this._deleteArticleUseCase) : super(const DeleteArticleInitial());

  Future<void> deleteArticle(String firestoreId) async {
    emit(const DeleteArticleLoading());
    try {
      final result = await _deleteArticleUseCase(params: firestoreId);
      if (result is DataSuccess) {
        emit(const DeleteArticleSuccess());
      } else if (result is DataFailed) {
        emit(DeleteArticleFailure(result.error?.error?.toString() ?? 'Delete failed'));
      }
    } catch (e) {
      emit(DeleteArticleFailure(e.toString()));
    }
  }
}

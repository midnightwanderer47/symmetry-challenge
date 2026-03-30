import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/update_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/upload_article_thumbnail.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/edit/edit_article_state.dart';

class EditArticleCubit extends Cubit<EditArticleState> {
  final UpdateArticleUseCase _updateArticleUseCase;
  final UploadArticleThumbnailUseCase _uploadThumbnailUseCase;

  EditArticleCubit(this._updateArticleUseCase, this._uploadThumbnailUseCase)
      : super(const EditArticleInitial());

  Future<void> updateArticle(ArticleEntity article,
      {String? thumbnailFilePath}) async {
    emit(const EditArticleLoading());
    try {
      ArticleEntity finalArticle = article;

      if (thumbnailFilePath != null) {
        final thumbResult =
            await _uploadThumbnailUseCase(params: thumbnailFilePath);
        if (thumbResult is DataSuccess) {
          finalArticle = article.copyWith(thumbnailURL: thumbResult.data);
        } else if (thumbResult is DataFailed) {
          emit(EditArticleFailure(thumbResult.error?.error?.toString() ??
              'Thumbnail upload failed'));
          return;
        }
      }

      final result = await _updateArticleUseCase(params: finalArticle);
      if (result is DataSuccess) {
        emit(const EditArticleSuccess());
      } else if (result is DataFailed) {
        emit(EditArticleFailure(
            result.error?.error?.toString() ?? 'Update failed'));
      }
    } catch (e) {
      emit(EditArticleFailure(e.toString()));
    }
  }
}

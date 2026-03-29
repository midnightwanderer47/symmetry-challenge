import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/upload_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/upload_article_thumbnail.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/upload/article_upload_state.dart';

class ArticleUploadCubit extends Cubit<ArticleUploadState> {
  final UploadArticleUseCase _uploadArticleUseCase;
  final UploadArticleThumbnailUseCase _uploadThumbnailUseCase;
  final User? Function() _getCurrentUser;

  ArticleUploadCubit(
    this._uploadArticleUseCase,
    this._uploadThumbnailUseCase, {
    User? Function()? getCurrentUser,
  })  : _getCurrentUser = getCurrentUser ?? (() => FirebaseAuth.instance.currentUser),
        super(const ArticleUploadInitial());

  Future<void> upload(ArticleEntity article, {String? thumbnailFilePath}) async {
    if (_getCurrentUser() == null) {
      emit(const ArticleUploadFailure('Authentication required'));
      return;
    }
    emit(const ArticleUploadLoading());
    try {
      String? thumbnailUrl;
      if (thumbnailFilePath != null) {
        final thumbResult = await _uploadThumbnailUseCase(params: thumbnailFilePath);
        if (thumbResult is DataSuccess) {
          thumbnailUrl = thumbResult.data;
        } else if (thumbResult is DataFailed) {
          emit(ArticleUploadFailure(thumbResult.error?.error?.toString() ?? 'Thumbnail upload failed'));
          return;
        }
      }

      final finalArticle = article.copyWith(
        thumbnailURL: thumbnailUrl,
        isUserArticle: true,
        createdAt: DateTime.now().toIso8601String(),
        userId: _getCurrentUser()!.uid,
      );

      final result = await _uploadArticleUseCase(params: finalArticle);
      if (result is DataSuccess) {
        emit(const ArticleUploadSuccess());
      } else if (result is DataFailed) {
        emit(ArticleUploadFailure(result.error?.error?.toString() ?? 'Upload failed'));
      }
    } catch (e) {
      emit(ArticleUploadFailure(e.toString()));
    }
  }
}

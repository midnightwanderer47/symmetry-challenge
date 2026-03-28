import 'package:equatable/equatable.dart';

abstract class ArticleUploadState extends Equatable {
  const ArticleUploadState();

  @override
  List<Object> get props => [];
}

class ArticleUploadInitial extends ArticleUploadState {
  const ArticleUploadInitial();
}

class ArticleUploadLoading extends ArticleUploadState {
  const ArticleUploadLoading();
}

class ArticleUploadSuccess extends ArticleUploadState {
  const ArticleUploadSuccess();
}

class ArticleUploadFailure extends ArticleUploadState {
  final String message;

  const ArticleUploadFailure(this.message);

  @override
  List<Object> get props => [message];
}

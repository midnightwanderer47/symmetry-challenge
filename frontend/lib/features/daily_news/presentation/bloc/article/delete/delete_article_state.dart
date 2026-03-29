import 'package:equatable/equatable.dart';

abstract class DeleteArticleState extends Equatable {
  const DeleteArticleState();

  @override
  List<Object> get props => [];
}

class DeleteArticleInitial extends DeleteArticleState {
  const DeleteArticleInitial();
}

class DeleteArticleLoading extends DeleteArticleState {
  const DeleteArticleLoading();
}

class DeleteArticleSuccess extends DeleteArticleState {
  const DeleteArticleSuccess();
}

class DeleteArticleFailure extends DeleteArticleState {
  final String message;

  const DeleteArticleFailure(this.message);

  @override
  List<Object> get props => [message];
}

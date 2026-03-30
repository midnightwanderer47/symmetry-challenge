import 'package:equatable/equatable.dart';

abstract class EditArticleState extends Equatable {
  const EditArticleState();

  @override
  List<Object> get props => [];
}

class EditArticleInitial extends EditArticleState {
  const EditArticleInitial();
}

class EditArticleLoading extends EditArticleState {
  const EditArticleLoading();
}

class EditArticleSuccess extends EditArticleState {
  const EditArticleSuccess();
}

class EditArticleFailure extends EditArticleState {
  final String message;

  const EditArticleFailure(this.message);

  @override
  List<Object> get props => [message];
}

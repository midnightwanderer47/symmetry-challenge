import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/update_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/upload_article_thumbnail.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/edit/edit_article_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/edit/edit_article_state.dart';

class MockUpdateArticleUseCase extends Mock implements UpdateArticleUseCase {}

class MockUploadArticleThumbnailUseCase extends Mock
    implements UploadArticleThumbnailUseCase {}

DioError _dioError() => DioError(
      requestOptions: RequestOptions(path: ''),
      error: Exception('network error'),
    );

const _article = ArticleEntity(
  title: 'Test Article',
  author: 'Author',
  firestoreId: 'doc123',
);

void main() {
  late MockUpdateArticleUseCase mockUpdateUseCase;
  late MockUploadArticleThumbnailUseCase mockThumbnailUseCase;
  late EditArticleCubit cubit;

  setUp(() {
    mockUpdateUseCase = MockUpdateArticleUseCase();
    mockThumbnailUseCase = MockUploadArticleThumbnailUseCase();
    cubit = EditArticleCubit(mockUpdateUseCase, mockThumbnailUseCase);
  });

  tearDown(() => cubit.close());

  test('initial state is EditArticleInitial', () {
    expect(cubit.state, const EditArticleInitial());
  });

  test('emits Loading then Success when update succeeds without thumbnail',
      () async {
    when(() => mockUpdateUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess(null));

    final states = <EditArticleState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.updateArticle(_article);
    await pumpEventQueue();
    await subscription.cancel();

    expect(states, [const EditArticleLoading(), const EditArticleSuccess()]);
    verifyNever(() => mockThumbnailUseCase(params: any(named: 'params')));
  });

  test('uploads thumbnail and emits Success when thumbnailFilePath is provided',
      () async {
    const newUrl = 'https://storage.example.com/thumb.jpg';
    when(() => mockThumbnailUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess(newUrl));
    when(() => mockUpdateUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess(null));

    final states = <EditArticleState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.updateArticle(_article, thumbnailFilePath: '/tmp/thumb.jpg');
    await pumpEventQueue();
    await subscription.cancel();

    expect(states, [const EditArticleLoading(), const EditArticleSuccess()]);
    verify(() => mockThumbnailUseCase(params: '/tmp/thumb.jpg')).called(1);
    verify(() =>
            mockUpdateUseCase(params: _article.copyWith(thumbnailURL: newUrl)))
        .called(1);
  });

  test('emits Failure when thumbnail upload fails', () async {
    when(() => mockThumbnailUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => DataFailed(_dioError()));

    final states = <EditArticleState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.updateArticle(_article, thumbnailFilePath: '/tmp/thumb.jpg');
    await pumpEventQueue();
    await subscription.cancel();

    expect(states.first, const EditArticleLoading());
    expect(states.last, isA<EditArticleFailure>());
    verifyNever(() => mockUpdateUseCase(params: any(named: 'params')));
  });

  test('emits Failure when article update fails', () async {
    when(() => mockUpdateUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => DataFailed(_dioError()));

    final states = <EditArticleState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.updateArticle(_article);
    await pumpEventQueue();
    await subscription.cancel();

    expect(states.first, const EditArticleLoading());
    final failure = states.last as EditArticleFailure;
    expect(failure.message, isNotEmpty);
  });

  test('emits Failure with exception message on unexpected error', () async {
    when(() => mockUpdateUseCase(params: any(named: 'params')))
        .thenThrow(Exception('unexpected'));

    final states = <EditArticleState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.updateArticle(_article);
    await pumpEventQueue();
    await subscription.cancel();

    expect(states.first, const EditArticleLoading());
    expect(states.last, isA<EditArticleFailure>());
  });
}

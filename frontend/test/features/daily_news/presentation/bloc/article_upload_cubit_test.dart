import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/upload_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/upload_article_thumbnail.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/upload/article_upload_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/upload/article_upload_state.dart';

class MockUploadArticleUseCase extends Mock implements UploadArticleUseCase {}

class MockUploadArticleThumbnailUseCase extends Mock
    implements UploadArticleThumbnailUseCase {}

class _MockUser extends Mock implements User {}

DioError _dioError() => DioError(
      requestOptions: RequestOptions(path: ''),
      error: Exception('test error'),
    );

const _article = ArticleEntity(
  title: 'Test Title',
  author: 'Test Author',
  content: 'Test Content',
  publishedAt: '2024-01-01T00:00:00.000Z',
);

void main() {
  late MockUploadArticleUseCase mockUploadUseCase;
  late MockUploadArticleThumbnailUseCase mockThumbnailUseCase;
  final mockUser = _MockUser();

  setUp(() {
    mockUploadUseCase = MockUploadArticleUseCase();
    mockThumbnailUseCase = MockUploadArticleThumbnailUseCase();
    registerFallbackValue(_article);
    registerFallbackValue('');
    when(() => mockUser.uid).thenReturn('test-uid');
  });

  ArticleUploadCubit buildCubit({
    bool authenticated = true,
    Duration uploadTimeout = const Duration(seconds: 30),
  }) =>
      ArticleUploadCubit(
        mockUploadUseCase,
        mockThumbnailUseCase,
        getCurrentUser: () => authenticated ? mockUser : null,
        uploadTimeout: uploadTimeout,
      );

  test('initial state is ArticleUploadInitial', () {
    expect(buildCubit().state, const ArticleUploadInitial());
  });

  test('state is Failure when not authenticated', () async {
    final cubit = buildCubit(authenticated: false);
    await cubit.upload(_article);
    expect(cubit.state, isA<ArticleUploadFailure>());
  });

  test('state is Success when upload without thumbnail succeeds', () async {
    when(() => mockUploadUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess(null));
    final cubit = buildCubit();
    await cubit.upload(_article);
    expect(cubit.state, const ArticleUploadSuccess());
  });

  test('state is Success when upload with thumbnail succeeds', () async {
    when(() => mockThumbnailUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess('https://example.com/thumb.jpg'));
    when(() => mockUploadUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess(null));
    final cubit = buildCubit();
    await cubit.upload(_article, thumbnailFilePath: '/path/img.jpg');
    expect(cubit.state, const ArticleUploadSuccess());
  });

  test('state is Failure when thumbnail upload fails', () async {
    when(() => mockThumbnailUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => DataFailed(_dioError()));
    final cubit = buildCubit();
    await cubit.upload(_article, thumbnailFilePath: '/path/img.jpg');
    expect(cubit.state, isA<ArticleUploadFailure>());
  });

  test('state is Failure when article upload fails', () async {
    when(() => mockUploadUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => DataFailed(_dioError()));
    final cubit = buildCubit();
    await cubit.upload(_article);
    expect(cubit.state, isA<ArticleUploadFailure>());
  });

  test('state is Failure when upload use case throws', () async {
    when(() => mockUploadUseCase(params: any(named: 'params')))
        .thenThrow(Exception('unexpected'));
    final cubit = buildCubit();
    await cubit.upload(_article);
    expect(cubit.state, isA<ArticleUploadFailure>());
  });

  test('emits Loading before uploading', () async {
    final emitted = <ArticleUploadState>[];
    when(() => mockUploadUseCase(params: any(named: 'params')))
        .thenAnswer((_) async => const DataSuccess(null));
    final cubit = buildCubit();
    cubit.stream.listen(emitted.add);
    await cubit.upload(_article);
    expect(emitted, contains(const ArticleUploadLoading()));
  });

  test('emits Failure with message when FirebaseAuthException thrown during upload', () async {
    when(() => mockUploadUseCase(params: any(named: 'params')))
        .thenThrow(FirebaseAuthException(code: 'operation-not-allowed'));
    final cubit = buildCubit();
    await cubit.upload(_article);
    expect(cubit.state, isA<ArticleUploadFailure>());
    expect(
      (cubit.state as ArticleUploadFailure).message,
      contains('operation-not-allowed'),
    );
  });

  test('emits Failure with message when FirebaseAuthException thrown during thumbnail upload', () async {
    when(() => mockThumbnailUseCase(params: any(named: 'params')))
        .thenThrow(FirebaseAuthException(code: 'permission-denied'));
    final cubit = buildCubit();
    await cubit.upload(_article, thumbnailFilePath: '/path/img.jpg');
    expect(cubit.state, isA<ArticleUploadFailure>());
    expect(
      (cubit.state as ArticleUploadFailure).message,
      contains('permission-denied'),
    );
  });

  test('emits Failure with timeout message when upload times out', () async {
    when(() => mockUploadUseCase(params: any(named: 'params')))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 200));
      return const DataSuccess(null);
    });
    final cubit = buildCubit(uploadTimeout: const Duration(milliseconds: 50));
    await cubit.upload(_article);
    expect(cubit.state, isA<ArticleUploadFailure>());
    expect(
      (cubit.state as ArticleUploadFailure).message,
      contains('timed out'),
    );
  });

  test('emits Failure with timeout message when thumbnail upload times out', () async {
    when(() => mockThumbnailUseCase(params: any(named: 'params')))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 200));
      return const DataSuccess('url');
    });
    final cubit = buildCubit(uploadTimeout: const Duration(milliseconds: 50));
    await cubit.upload(_article, thumbnailFilePath: '/path/img.jpg');
    expect(cubit.state, isA<ArticleUploadFailure>());
    expect(
      (cubit.state as ArticleUploadFailure).message,
      contains('timed out'),
    );
  });
}

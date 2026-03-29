import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/delete_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_user_articles.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/upload_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/upload_article_thumbnail.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/delete/delete_article_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_articles_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_articles_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/upload/article_upload_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/upload/article_upload_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/user/user_articles_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/user/user_articles_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/theme/theme_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/pages/main/main_screen.dart';

class _MockRepository extends Mock implements ArticleRepository {}

class _MockUser extends Mock implements User {}

/// Seeded RemoteArticlesCubit that never calls the use case.
class _SeededRemoteCubit extends RemoteArticlesCubit {
  _SeededRemoteCubit(RemoteArticlesState initial)
      : super(GetArticleUseCase(_MockRepository())) {
    emit(initial);
  }

  @override
  Future<void> fetchArticles() async {}
}

/// Seeded ArticleUploadCubit that stays idle.
class _SeededUploadCubit extends ArticleUploadCubit {
  _SeededUploadCubit()
      : super(
          UploadArticleUseCase(_MockRepository()),
          UploadArticleThumbnailUseCase(_MockRepository()),
          getCurrentUser: () => _MockUser(),
        ) {
    emit(const ArticleUploadInitial());
  }
}

/// Seeded UserArticlesCubit that stays idle.
class _SeededUserCubit extends UserArticlesCubit {
  _SeededUserCubit()
      : super(GetUserArticlesUseCase(_MockRepository())) {
    emit(const UserArticlesInitial());
  }

  @override
  Future<void> fetchUserArticles() async {}
}

final _sl = GetIt.instance;

Widget _buildApp() {
  final remoteCubit = _SeededRemoteCubit(const RemoteArticlesLoading());
  return MultiBlocProvider(
    providers: [
      BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
      BlocProvider<RemoteArticlesCubit>.value(value: remoteCubit),
    ],
    child: MaterialApp(
      home: MainScreen(authStateStream: Stream.value(_MockUser())),
    ),
  );
}

void main() {
  setUp(() async {
    await _sl.reset();
    _sl.registerFactory<ArticleUploadCubit>(() => _SeededUploadCubit());
    _sl.registerFactory<UserArticlesCubit>(() => _SeededUserCubit());
    _sl.registerFactory<DeleteArticleCubit>(
        () => DeleteArticleCubit(DeleteArticleUseCase(_MockRepository())));
  });
  tearDown(() async => _sl.reset());

  testWidgets('default selected tab is Feed (index 0)', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    final nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(nav.currentIndex, 0);
    expect(find.text('Feed'), findsOneWidget);
  });

  testWidgets('tapping Create tab switches to index 1', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    await tester.tap(find.text('Create'));
    await tester.pump();

    final nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(nav.currentIndex, 1);
  });

  testWidgets('tapping My Articles tab switches to index 2', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    await tester.tap(find.text('My Articles'));
    await tester.pump();

    final nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(nav.currentIndex, 2);
  });

  testWidgets('switching back to Feed after My Articles preserves index 0', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    // Switch to My Articles
    await tester.tap(find.text('My Articles'));
    await tester.pump();

    // Switch back to Feed
    await tester.tap(find.text('Feed'));
    await tester.pump();

    final nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(nav.currentIndex, 0);
  });

  testWidgets('IndexedStack keeps all 3 tab widgets in tree', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.children.length, 3);
  });
}

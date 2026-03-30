import 'package:floor/floor.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:news_app_clean_architecture/core/constants/constants.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/firestore/firestore_article_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/firestore/firestore_article_data_source_impl.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/remote/news_api_service.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/storage/firebase_storage_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/storage/firebase_storage_data_source_impl.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/repository/article_repository_impl.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/repository/article_repository.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/delete_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/update_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/get_user_articles.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/search_articles.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/upload_article.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/usecases/upload_article_thumbnail.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_articles_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/upload/article_upload_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/user/user_articles_cubit.dart';
import 'features/daily_news/data/data_sources/local/app_database.dart';
import 'features/daily_news/domain/usecases/get_saved_article.dart';
import 'features/daily_news/domain/usecases/remove_article.dart';
import 'features/daily_news/domain/usecases/save_article.dart';
import 'features/daily_news/presentation/bloc/article/local/local_article_bloc.dart';
import 'features/daily_news/presentation/bloc/article/delete/delete_article_cubit.dart';
import 'features/daily_news/presentation/bloc/article/edit/edit_article_cubit.dart';
import 'features/daily_news/presentation/bloc/article/search/search_articles_cubit.dart';
import 'features/daily_news/presentation/bloc/theme/theme_cubit.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  final migration1to2 = Migration(1, 2, (database) async {
    await database.execute('ALTER TABLE article ADD COLUMN firestoreId TEXT');
    await database.execute('ALTER TABLE article ADD COLUMN userId TEXT');
  });

  final database = await $FloorAppDatabase
      .databaseBuilder('app_database.db')
      .addMigrations([migration1to2]).build();
  sl.registerSingleton<AppDatabase>(database);

  // Dio
  sl.registerSingleton<Dio>(Dio(BaseOptions(baseUrl: newsAPIBaseURL)));

  // Dependencies
  sl.registerSingleton<NewsApiService>(NewsApiService(sl()));

  // Firebase data sources
  sl.registerSingleton<FirestoreArticleDataSource>(
      FirestoreArticleDataSourceImpl());

  sl.registerSingleton<FirebaseStorageDataSource>(
      FirebaseStorageDataSourceImpl());

  sl.registerSingleton<ArticleRepository>(
      ArticleRepositoryImpl(sl(), sl(), sl(), sl()));

  //UseCases
  sl.registerSingleton<GetArticleUseCase>(GetArticleUseCase(sl()));

  sl.registerSingleton<GetSavedArticleUseCase>(GetSavedArticleUseCase(sl()));

  sl.registerSingleton<SaveArticleUseCase>(SaveArticleUseCase(sl()));

  sl.registerSingleton<RemoveArticleUseCase>(RemoveArticleUseCase(sl()));

  sl.registerSingleton<UploadArticleUseCase>(UploadArticleUseCase(sl()));

  sl.registerSingleton<UploadArticleThumbnailUseCase>(
      UploadArticleThumbnailUseCase(sl()));

  sl.registerSingleton<GetUserArticlesUseCase>(GetUserArticlesUseCase(sl()));

  sl.registerSingleton<SearchArticlesUseCase>(SearchArticlesUseCase(sl()));

  sl.registerSingleton<DeleteArticleUseCase>(DeleteArticleUseCase(sl()));

  sl.registerSingleton<UpdateArticleUseCase>(UpdateArticleUseCase(sl()));

  //Blocs
  sl.registerFactory<ArticleUploadCubit>(() => ArticleUploadCubit(sl(), sl()));

  sl.registerFactory<UserArticlesCubit>(() => UserArticlesCubit(sl()));

  sl.registerFactory<RemoteArticlesBloc>(() => RemoteArticlesBloc(sl()));

  sl.registerFactory<RemoteArticlesCubit>(() => RemoteArticlesCubit(sl()));

  sl.registerFactory<LocalArticleBloc>(
      () => LocalArticleBloc(sl(), sl(), sl()));

  sl.registerFactory<SearchArticlesCubit>(() => SearchArticlesCubit(sl()));

  sl.registerFactory<DeleteArticleCubit>(() => DeleteArticleCubit(sl()));

  sl.registerFactory<EditArticleCubit>(() => EditArticleCubit(sl(), sl()));

  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
}

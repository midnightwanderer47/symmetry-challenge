import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/delete/delete_article_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/delete/delete_article_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/user/user_articles_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/user/user_articles_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/widgets/article_tile.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/widgets/delete_article_dialog.dart';
import 'package:news_app_clean_architecture/injection_container.dart';

class UserArticlesScreen extends StatelessWidget {
  const UserArticlesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<UserArticlesCubit>()..fetchUserArticles(),
        ),
        BlocProvider(
          create: (_) => sl<DeleteArticleCubit>(),
        ),
      ],
      child: BlocListener<DeleteArticleCubit, DeleteArticleState>(
        listener: (context, state) {
          if (state is DeleteArticleSuccess) {
            context.read<UserArticlesCubit>().fetchUserArticles();
          } else if (state is DeleteArticleFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('My Articles'),
          ),
          body: BlocBuilder<UserArticlesCubit, UserArticlesState>(
            builder: (context, state) {
              if (state is UserArticlesLoading) {
                return const Center(child: CupertinoActivityIndicator());
              }
              if (state is UserArticlesError) {
                final onSurface = Theme.of(context).colorScheme.onSurface;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: onSurface),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: onSurface),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => context
                              .read<UserArticlesCubit>()
                              .fetchUserArticles(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (state is UserArticlesLoaded) {
                if (state.articles.isEmpty) {
                  final onSurface = Theme.of(context).colorScheme.onSurface;
                  final mutedColor =
                      onSurface.withValues(alpha: onSurface.a * 0.4);
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined,
                            size: 64, color: mutedColor),
                        const SizedBox(height: 16),
                        Text('No articles yet',
                            style: TextStyle(color: mutedColor)),
                      ],
                    ),
                  );
                }
                String? currentUid;
                try {
                  currentUid = FirebaseAuth.instance.currentUser?.uid;
                } catch (_) {
                  currentUid = null;
                }
                return RefreshIndicator(
                  onRefresh:
                      context.read<UserArticlesCubit>().fetchUserArticles,
                  child: ListView.builder(
                    itemCount: state.articles.length,
                    itemBuilder: (_, i) {
                      final article = state.articles[i];
                      final isOwner = currentUid != null &&
                          article.userId == currentUid &&
                          article.firestoreId != null;
                      return ArticleWidget(
                        article: article,
                        currentUserUid: currentUid,
                        isRemovable: isOwner,
                        showYouBadge: false,
                        onRemove: isOwner
                            ? (ArticleEntity a) =>
                                showDeleteArticleConfirmation(
                                  context,
                                  () => context
                                      .read<DeleteArticleCubit>()
                                      .deleteArticle(a.firestoreId!),
                                )
                            : null,
                        onArticlePressed: (ArticleEntity a) async {
                          final result = await Navigator.pushNamed(
                              context, '/ArticleDetails',
                              arguments: a);
                          if (result == true && context.mounted) {
                            context
                                .read<UserArticlesCubit>()
                                .fetchUserArticles();
                          }
                        },
                      );
                    },
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/config/routes/routes.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_articles_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/remote/remote_articles_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/theme/theme_cubit.dart';

import '../../../domain/entities/article.dart';
import '../../widgets/article_tile.dart';

class DailyNews extends StatelessWidget {
  const DailyNews({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildPage();
  }

  _buildAppbar(BuildContext context) {
    final titleStyle = Theme.of(context).appBarTheme.titleTextStyle ??
        Theme.of(context).textTheme.titleLarge;

    return AppBar(
      automaticallyImplyLeading: false,
      title: const SizedBox.shrink(),
      flexibleSpace: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: Text('Daily News', style: titleStyle)),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      final remoteState =
                          context.read<RemoteArticlesCubit>().state;
                      final articles = remoteState is RemoteArticlesLoaded
                          ? remoteState.articles
                          : <ArticleEntity>[];
                      Navigator.pushNamed(context, AppRoutes.searchRoute,
                          arguments: articles);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark),
                    onPressed: () => _onShowSavedArticlesViewTapped(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => _showSettingsSheet(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return BlocProvider.value(
          value: context.read<ThemeCubit>(),
          child: const _SettingsSheet(),
        );
      },
    );
  }

  _buildPage() {
    return BlocBuilder<RemoteArticlesCubit, RemoteArticlesState>(
      builder: (context, state) {
        if (state is RemoteArticlesLoading) {
          return Scaffold(
              appBar: _buildAppbar(context),
              body: const Center(child: CupertinoActivityIndicator()));
        }
        if (state is RemoteArticlesError) {
          return Scaffold(
              appBar: _buildAppbar(context),
              body: const Center(child: Icon(Icons.refresh)));
        }
        if (state is RemoteArticlesLoaded) {
          return _buildArticlesPage(context, state);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildArticlesPage(
      BuildContext context, RemoteArticlesLoaded state) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final articles = state.articles;

    return Scaffold(
      appBar: _buildAppbar(context),
      body: RefreshIndicator(
        onRefresh: () => context.read<RemoteArticlesCubit>().refresh(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: articles.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == articles.length) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: state.isLoadingMore
                    ? const Center(child: CupertinoActivityIndicator())
                    : Center(
                        child: TextButton(
                          onPressed: () =>
                              context.read<RemoteArticlesCubit>().loadMore(),
                          child: const Text('Load more'),
                        ),
                      ),
              );
            }
            return ArticleWidget(
              article: articles[index],
              currentUserUid: currentUid,
              onArticlePressed: (article) => _onArticlePressed(context, article),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result =
              await Navigator.pushNamed(context, AppRoutes.uploadArticleRoute);
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Semantics(
                  liveRegion: true,
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Article published!'),
                    ],
                  ),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            context.read<RemoteArticlesCubit>().refresh();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _onArticlePressed(BuildContext context, ArticleEntity article) async {
    final result = await Navigator.pushNamed(
        context, AppRoutes.articleDetailsRoute,
        arguments: article);
    if (result == true && context.mounted) {
      context.read<RemoteArticlesCubit>().refresh();
    }
  }

  void _onShowSavedArticlesViewTapped(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.savedArticlesRoute);
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Appearance',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.dark_mode_outlined, color: colorScheme.onSurface),
              const SizedBox(width: 16),
              Text('Dark Mode', style: textTheme.bodyLarge),
              const Spacer(),
              Switch(
                value: isDark,
                onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
                    icon: Icon(
                      context.watch<ThemeCubit>().state == ThemeMode.dark
                          ? Icons.brightness_7
                          : Icons.brightness_4,
                    ),
                    onPressed: () =>
                        context.read<ThemeCubit>().toggleTheme(),
                  ),
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
                    onPressed: () =>
                        _onShowSavedArticlesViewTapped(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          return _buildArticlesPage(context, state.articles);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildArticlesPage(
      BuildContext context, List<ArticleEntity> articles) {
    List<Widget> articleWidgets = [];
    for (var article in articles) {
      articleWidgets.add(ArticleWidget(
        article: article,
        onArticlePressed: (article) => _onArticlePressed(context, article),
      ));
    }

    return Scaffold(
      appBar: _buildAppbar(context),
      body: RefreshIndicator(
        onRefresh: () => context.read<RemoteArticlesCubit>().refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: articleWidgets,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRoutes.uploadArticleRoute);
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

  void _onArticlePressed(BuildContext context, ArticleEntity article) {
    Navigator.pushNamed(context, AppRoutes.articleDetailsRoute, arguments: article);
  }

  void _onShowSavedArticlesViewTapped(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.savedArticlesRoute);
  }
}

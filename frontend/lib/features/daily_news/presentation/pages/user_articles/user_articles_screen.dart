import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/user/user_articles_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/user/user_articles_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/widgets/article_tile.dart';
import 'package:news_app_clean_architecture/injection_container.dart';

class UserArticlesScreen extends StatelessWidget {
  const UserArticlesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<UserArticlesCubit>()..fetchUserArticles(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Articles',
            style: TextStyle(color: Colors.black),
          ),
        ),
        body: BlocBuilder<UserArticlesCubit, UserArticlesState>(
          builder: (context, state) {
            if (state is UserArticlesLoading) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (state is UserArticlesError) {
              return const Center(child: Icon(Icons.refresh));
            }
            if (state is UserArticlesLoaded) {
              if (state.articles.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No articles yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: context.read<UserArticlesCubit>().fetchUserArticles,
                child: ListView.builder(
                  itemCount: state.articles.length,
                  itemBuilder: (_, i) => ArticleWidget(
                    article: state.articles[i],
                    onArticlePressed: (ArticleEntity article) =>
                        Navigator.pushNamed(context, '/ArticleDetails',
                            arguments: article),
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

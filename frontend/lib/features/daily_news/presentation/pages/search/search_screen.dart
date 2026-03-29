import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/config/routes/routes.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/search/search_articles_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/search/search_articles_state.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/widgets/article_tile.dart';
import 'package:news_app_clean_architecture/injection_container.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchArticlesCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: _buildSearchField(context),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search articles...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
      style: const TextStyle(color: Colors.black),
      onChanged: (query) => context.read<SearchArticlesCubit>().queryChanged(query),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<SearchArticlesCubit, SearchArticlesState>(
      builder: (context, state) {
        if (state is SearchArticlesLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (state is SearchArticlesLoaded) {
          return _buildResults(context, state.articles);
        }
        if (state is SearchArticlesEmpty) {
          return Center(
            child: Text('No articles match "${_controller.text}"'),
          );
        }
        if (state is SearchArticlesError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildResults(BuildContext context, List<ArticleEntity> articles) {
    return ListView.builder(
      itemCount: articles.length,
      itemBuilder: (context, index) {
        return ArticleWidget(
          article: articles[index],
          onArticlePressed: (article) =>
              Navigator.pushNamed(context, AppRoutes.articleDetailsRoute, arguments: article),
        );
      },
    );
  }
}

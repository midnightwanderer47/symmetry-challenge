import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/user/user_articles_cubit.dart';
import 'package:news_app_clean_architecture/injection_container.dart';

import '../home/daily_news.dart';
import '../upload_article/upload_article.dart';
import '../user_articles/user_articles_screen.dart';

class MainScreen extends StatefulWidget {
  @visibleForTesting
  final Stream<User?>? authStateStream;

  const MainScreen({Key? key, this.authStateStream}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final UserArticlesCubit _userArticlesCubit;

  @override
  void initState() {
    super.initState();
    _userArticlesCubit = sl<UserArticlesCubit>()..fetchUserArticles();
  }

  @override
  void dispose() {
    _userArticlesCubit.close();
    super.dispose();
  }

  void _onUploadSuccess() {
    _userArticlesCubit.fetchUserArticles();
    setState(() => _currentIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const DailyNews(),
      UploadArticleView(
        authStateStream: widget.authStateStream,
        onSuccess: _onUploadSuccess,
      ),
      const UserArticlesScreen(),
    ];

    return BlocProvider.value(
      value: _userArticlesCubit,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              _userArticlesCubit.fetchUserArticles();
            }
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              label: 'My Articles',
            ),
          ],
        ),
      ),
    );
  }
}

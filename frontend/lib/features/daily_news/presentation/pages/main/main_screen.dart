import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  late final List<Widget> _tabs = [
    const DailyNews(),
    UploadArticleView(authStateStream: widget.authStateStream),
    const UserArticlesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
    );
  }
}

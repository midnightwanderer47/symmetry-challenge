import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/firestore/firestore_article_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';

class FirestoreArticleDataSourceImpl implements FirestoreArticleDataSource {
  final FirebaseFirestore _firestore;

  FirestoreArticleDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> uploadArticle(ArticleModel article) async {
    try {
      await _firestore.collection('articles').add(article.toFirestore());
    } on FirebaseException {
      rethrow;
    }
  }

  @override
  Future<List<ArticleModel>> getUserArticles() async {
    try {
      final snapshot = await _firestore
          .collection('articles')
          .where('isUserArticle', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => ArticleModel.fromFirestore(doc)).toList();
    } on FirebaseException {
      rethrow;
    }
  }
}

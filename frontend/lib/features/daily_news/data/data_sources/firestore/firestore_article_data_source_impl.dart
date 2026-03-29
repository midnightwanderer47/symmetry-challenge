import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/firestore/firestore_article_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';

class FirestoreArticleDataSourceImpl implements FirestoreArticleDataSource {
  final FirebaseFirestore _firestore;

  static const _placeholderThumbnail =
      'https://via.placeholder.com/300x200/cccccc/666666?text=No+Image';

  FirestoreArticleDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  ArticleModel _withValidThumbnail(ArticleModel article) {
    if (article.thumbnailURL == null || article.thumbnailURL!.isEmpty) {
      return ArticleModel.fromEntity(
        article.toEntity().copyWith(thumbnailURL: _placeholderThumbnail),
      );
    }
    return article;
  }

  @override
  Future<void> uploadArticle(ArticleModel article) async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw FirebaseException(
        plugin: 'firestore',
        code: 'unauthenticated',
        message: 'User not authenticated',
      );
    }
    try {
      final validArticle = _withValidThumbnail(article);
      await _firestore.collection('articles').add(validArticle.toFirestore());
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

  @override
  Future<void> deleteArticle(String firestoreId) async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw FirebaseException(
        plugin: 'firestore',
        code: 'unauthenticated',
        message: 'User not authenticated',
      );
    }
    try {
      await _firestore.collection('articles').doc(firestoreId).delete();
    } on FirebaseException {
      rethrow;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_app_clean_architecture/core/constants/constants.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/firestore/firestore_article_data_source.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/paginated_articles_result.dart';

class FirestoreArticleDataSourceImpl implements FirestoreArticleDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth? _authOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  static const int kDefaultPageSize = 20;

  FirestoreArticleDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authOverride = auth;

  ArticleModel _withValidThumbnail(ArticleModel article) {
    if (article.thumbnailURL == null || article.thumbnailURL!.isEmpty) {
      return ArticleModel.fromEntity(
        article.toEntity().copyWith(thumbnailURL: kDefaultImage),
      );
    }
    return article;
  }

  @override
  Future<void> uploadArticle(ArticleModel article) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firestore',
        code: 'unauthenticated',
        message: 'User not authenticated',
      );
    }
    try {
      final withUid = ArticleModel.fromEntity(
        article.toEntity().copyWith(userId: currentUser.uid),
      );
      final validArticle = _withValidThumbnail(withUid);
      await _firestore.collection('articles').add(validArticle.toFirestore());
    } on FirebaseException {
      rethrow;
    }
  }

  @override
  Future<List<ArticleModel>> getUserArticles() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final uid = user.uid;
    try {
      final snapshot = await _firestore
          .collection('articles')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ArticleModel.fromFirestore(doc))
          .toList();
    } on FirebaseException {
      rethrow;
    }
  }

  @override
  Future<List<ArticleModel>> getCommunityArticles() async {
    try {
      final snapshot = await _firestore
          .collection('articles')
          .where('isUserArticle', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ArticleModel.fromFirestore(doc))
          .toList();
    } on FirebaseException {
      rethrow;
    }
  }

  @override
  Future<PaginatedArticlesResult> getUserArticlesPage({
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('articles')
          .where('isUserArticle', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      final articles = querySnapshot.docs
          .map((doc) => ArticleModel.fromFirestore(doc))
          .toList();
      final hasMore = articles.length == limit;
      final lastDocument =
          querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

      return PaginatedArticlesResult(
        articles: articles,
        lastDocument: lastDocument,
        hasMore: hasMore,
      );
    } on FirebaseException {
      rethrow;
    }
  }

  @override
  Future<void> deleteArticle(String firestoreId) async {
    if (_auth.currentUser == null) {
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

  @override
  Future<void> updateArticle(String firestoreId, ArticleModel patch) async {
    if (_auth.currentUser == null) {
      throw FirebaseException(
        plugin: 'firestore',
        code: 'unauthenticated',
        message: 'User not authenticated',
      );
    }
    try {
      await _firestore
          .collection('articles')
          .doc(firestoreId)
          .update(patch.toFirestoreUpdate());
    } on FirebaseException {
      rethrow;
    }
  }
}

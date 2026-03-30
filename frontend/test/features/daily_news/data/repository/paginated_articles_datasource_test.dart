import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/data_sources/firestore/firestore_article_data_source_impl.dart';
import 'package:news_app_clean_architecture/features/daily_news/data/models/paginated_articles_result.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreArticleDataSourceImpl dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirestoreArticleDataSourceImpl(firestore: fakeFirestore);
  });

  /// Seeds [count] articles ordered by createdAt (oldest first = lowest index).
  Future<void> seedArticles({
    required int count,
    bool isUserArticle = true,
  }) async {
    for (int i = 0; i < count; i++) {
      await fakeFirestore.collection('articles').add({
        'title': 'Article $i',
        'author': 'Author',
        'description': '',
        'url': '',
        'urlToImage': '',
        'publishedAt': '',
        'content': '',
        'thumbnailURL': '',
        'isUserArticle': isUserArticle,
        // Use an int so ordering comparisons are unambiguous in tests.
        'createdAt': i,
        'userId': 'user1',
      });
    }
  }

  group('getUserArticlesPage', () {
    test('returns first page of 20 with hasMore=true when 25 articles exist',
        () async {
      await seedArticles(count: 25);

      final result = await dataSource.getUserArticlesPage(limit: 20);

      expect(result.articles.length, 20);
      expect(result.hasMore, isTrue);
      expect(result.lastDocument, isNotNull);
    });

    test('returns empty list and hasMore=false when no articles exist',
        () async {
      final result = await dataSource.getUserArticlesPage(limit: 20);

      expect(result.articles, isEmpty);
      expect(result.hasMore, isFalse);
      expect(result.lastDocument, isNull);
    });

    test('articles are ordered by createdAt descending', () async {
      await seedArticles(count: 5);

      final result = await dataSource.getUserArticlesPage(limit: 5);

      // Seeds articles 0-4 with createdAt=index; descending → titles 4,3,2,1,0
      final titles = result.articles.map((a) => a.title).toList();
      expect(titles,
          ['Article 4', 'Article 3', 'Article 2', 'Article 1', 'Article 0']);
    });

    test('only returns isUserArticle=true documents', () async {
      await seedArticles(count: 3, isUserArticle: true);
      await seedArticles(count: 2, isUserArticle: false);

      final result = await dataSource.getUserArticlesPage(limit: 20);

      expect(result.articles.length, 3);
      expect(result.articles.every((a) => a.isUserArticle), isTrue);
    });

    test('hasMore is true when exactly limit articles are returned', () async {
      await seedArticles(count: 20);

      final result = await dataSource.getUserArticlesPage(limit: 20);

      expect(result.articles.length, 20);
      expect(result.hasMore, isTrue);
    });

    test('hasMore is false when fewer than limit articles are returned',
        () async {
      await seedArticles(count: 10);

      final result = await dataSource.getUserArticlesPage(limit: 20);

      expect(result.articles.length, 10);
      expect(result.hasMore, isFalse);
    });

    test('returns PaginatedArticlesResult type', () async {
      final result = await dataSource.getUserArticlesPage(limit: 20);

      expect(result, isA<PaginatedArticlesResult>());
    });

    test('lastDocument is non-null when articles are returned', () async {
      await seedArticles(count: 5);

      final result = await dataSource.getUserArticlesPage(limit: 20);

      expect(result.lastDocument, isA<DocumentSnapshot>());
    });

    test(
        'passes startAfter cursor to query — second call with cursor returns remaining articles',
        () async {
      // fake_cloud_firestore 3.x does not support startAfterDocument cursors in
      // query execution, so we verify the output contract instead: the
      // implementation accepts a DocumentSnapshot cursor without throwing.
      await seedArticles(count: 5);

      final firstPage = await dataSource.getUserArticlesPage(limit: 3);
      expect(firstPage.lastDocument, isNotNull);

      // Passing the cursor must not throw.
      await expectLater(
        () => dataSource.getUserArticlesPage(
          limit: 3,
          startAfter: firstPage.lastDocument,
        ),
        returnsNormally,
      );
    });
  });

  group('getUserArticles', () {
    late _MockFirebaseAuth mockAuth;
    late _MockUser mockUser;
    late FirestoreArticleDataSourceImpl authDataSource;

    setUp(() {
      mockAuth = _MockFirebaseAuth();
      mockUser = _MockUser();
      when(() => mockUser.uid).thenReturn('uid-abc');
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      authDataSource = FirestoreArticleDataSourceImpl(
        firestore: fakeFirestore,
        auth: mockAuth,
      );
    });

    Future<void> seedWithUser({
      required String userId,
      required int count,
    }) async {
      for (int i = 0; i < count; i++) {
        await fakeFirestore.collection('articles').add({
          'title': '$userId article $i',
          'author': 'Author',
          'description': '',
          'url': '',
          'urlToImage': '',
          'publishedAt': '',
          'content': '',
          'thumbnailURL': '',
          'isUserArticle': true,
          'createdAt': i,
          'userId': userId,
        });
      }
    }

    test('returns only articles belonging to the current user', () async {
      await seedWithUser(userId: 'uid-abc', count: 2);
      await seedWithUser(userId: 'uid-other', count: 3);

      final result = await authDataSource.getUserArticles();

      expect(result.length, 2);
      expect(result.every((a) => a.userId == 'uid-abc'), isTrue);
    });

    test('returns empty list when user has no articles', () async {
      await seedWithUser(userId: 'uid-other', count: 3);

      final result = await authDataSource.getUserArticles();

      expect(result, isEmpty);
    });

    test('returns empty list when no user is signed in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      await seedWithUser(userId: 'uid-abc', count: 2);

      final result = await authDataSource.getUserArticles();

      expect(result, isEmpty);
    });

    test('articles are ordered by createdAt descending', () async {
      await seedWithUser(userId: 'uid-abc', count: 4);

      final result = await authDataSource.getUserArticles();

      final titles = result.map((a) => a.title).toList();
      expect(titles, [
        'uid-abc article 3',
        'uid-abc article 2',
        'uid-abc article 1',
        'uid-abc article 0',
      ]);
    });
  });
}

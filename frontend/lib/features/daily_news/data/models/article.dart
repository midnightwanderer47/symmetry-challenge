import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floor/floor.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import '../../../../core/constants/constants.dart';

@Entity(tableName: 'article', primaryKeys: ['id'])
class ArticleModel extends ArticleEntity {
  const ArticleModel({
    int? id,
    String? author,
    String? title,
    String? description,
    String? url,
    String? urlToImage,
    String? publishedAt,
    String? content,
    String? thumbnailURL,
    bool isUserArticle = false,
    String? createdAt,
    String? updatedAt,
    String? firestoreId,
    String? userId,
  }) : super(
          id: id,
          author: author,
          title: title,
          description: description,
          url: url,
          urlToImage: urlToImage,
          publishedAt: publishedAt,
          content: content,
          thumbnailURL: thumbnailURL,
          isUserArticle: isUserArticle,
          createdAt: createdAt,
          updatedAt: updatedAt,
          firestoreId: firestoreId,
          userId: userId,
        );

  factory ArticleModel.fromJson(Map<String, dynamic> map) {
    return ArticleModel(
      author: map['author'] ?? "",
      title: map['title'] ?? "",
      description: map['description'] ?? "",
      url: map['url'] ?? "",
      urlToImage: map['urlToImage'] != null && map['urlToImage'] != ""
          ? map['urlToImage']
          : kDefaultImage,
      publishedAt: map['publishedAt'] ?? "",
      content: map['content'] ?? "",
    );
  }

  factory ArticleModel.fromEntity(ArticleEntity entity) {
    return ArticleModel(
      id: entity.id,
      author: entity.author,
      title: entity.title,
      description: entity.description,
      url: entity.url,
      urlToImage: entity.urlToImage,
      publishedAt: entity.publishedAt,
      content: entity.content,
      thumbnailURL: entity.thumbnailURL,
      isUserArticle: entity.isUserArticle,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      firestoreId: entity.firestoreId,
      userId: entity.userId,
    );
  }

  factory ArticleModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    final rawUrlToImage = (map['urlToImage'] as String?)?.trim();
    final rawThumbnail = (map['thumbnailURL'] as String?)?.trim();
    final resolvedImage =
        (rawUrlToImage != null && rawUrlToImage.isNotEmpty)
            ? rawUrlToImage
            : (rawThumbnail != null && rawThumbnail.isNotEmpty)
                ? rawThumbnail
                : kDefaultImage;
    return ArticleModel(
      author: map['author'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      url: map['url'] ?? '',
      urlToImage: resolvedImage,
      publishedAt: map['publishedAt'] ?? '',
      content: map['content'] ?? '',
      thumbnailURL: rawThumbnail,
      isUserArticle: map['isUserArticle'] ?? false,
      createdAt: map['createdAt']?.toString(),
      updatedAt: map['updatedAt']?.toString(),
      firestoreId: doc.id,
      userId: map['userId']?.toString(),
    );
  }

  ArticleEntity toEntity() => ArticleEntity(
        id: id,
        author: author,
        title: title,
        description: description,
        url: url,
        urlToImage: urlToImage,
        publishedAt: publishedAt,
        content: content,
        thumbnailURL: thumbnailURL,
        isUserArticle: isUserArticle,
        createdAt: createdAt,
        updatedAt: updatedAt,
        firestoreId: firestoreId,
        userId: userId,
      );

  Map<String, dynamic> toFirestoreUpdate() {
    final thumb = (thumbnailURL != null && thumbnailURL!.isNotEmpty)
        ? thumbnailURL!
        : null;
    return {
      'author': author ?? '',
      'title': title ?? '',
      'description': description ?? '',
      'content': content ?? '',
      'urlToImage': thumb ??
          (urlToImage != null && urlToImage!.isNotEmpty
              ? urlToImage!
              : kDefaultImage),
      'publishedAt': publishedAt ?? '',
      'thumbnailURL': thumb ??
          'https://via.placeholder.com/300x200/cccccc/666666?text=No+Image',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'author': author ?? '',
      'title': title ?? '',
      'description': description ?? '',
      'url': url ?? '',
      'urlToImage': (urlToImage != null && urlToImage!.isNotEmpty)
          ? urlToImage
          : (thumbnailURL != null && thumbnailURL!.isNotEmpty)
              ? thumbnailURL
              : kDefaultImage,
      'publishedAt': publishedAt ?? '',
      'content': content ?? '',
      'thumbnailURL': (thumbnailURL != null && thumbnailURL!.isNotEmpty)
          ? thumbnailURL
          : 'https://via.placeholder.com/300x200/cccccc/666666?text=No+Image',
      'isUserArticle': isUserArticle,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': userId ?? '',
    };
  }
}

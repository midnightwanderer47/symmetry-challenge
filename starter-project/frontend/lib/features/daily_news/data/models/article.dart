import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floor/floor.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import '../../../../core/constants/constants.dart';

@Entity(tableName: 'article',primaryKeys: ['id'])
class ArticleModel extends ArticleEntity {
  const ArticleModel({
    int ? id,
    String ? author,
    String ? title,
    String ? description,
    String ? url,
    String ? urlToImage,
    String ? publishedAt,
    String ? content,
    String ? thumbnailURL,
    bool isUserArticle = false,
    String ? createdAt,
  }): super(
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
  );

  factory ArticleModel.fromJson(Map < String, dynamic > map) {
    return ArticleModel(
      author: map['author'] ?? "",
      title: map['title'] ?? "",
      description: map['description'] ?? "",
      url: map['url'] ?? "",
      urlToImage: map['urlToImage'] != null && map['urlToImage'] != "" ? map['urlToImage'] : kDefaultImage,
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
    );
  }

  factory ArticleModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return ArticleModel(
      author: map['author'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      url: map['url'] ?? '',
      urlToImage: map['urlToImage'] ?? kDefaultImage,
      publishedAt: map['publishedAt'] ?? '',
      content: map['content'] ?? '',
      thumbnailURL: map['thumbnailURL'],
      isUserArticle: map['isUserArticle'] ?? false,
      createdAt: map['createdAt']?.toString(),
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
  );

  Map<String, dynamic> toFirestore() {
    return {
      'author': author ?? '',
      'title': title ?? '',
      'description': description ?? '',
      'url': url ?? '',
      'urlToImage': urlToImage ?? '',
      'publishedAt': publishedAt ?? '',
      'content': content ?? '',
      'thumbnailURL': (thumbnailURL != null && thumbnailURL!.isNotEmpty)
          ? thumbnailURL
          : 'https://via.placeholder.com/300x200/cccccc/666666?text=No+Image',
      'isUserArticle': isUserArticle,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/core/constants/constants.dart';

class ArticleEntity extends Equatable{
  final int ? id;
  final String ? author;
  final String ? title;
  final String ? description;
  final String ? url;
  final String ? urlToImage;
  final String ? publishedAt;
  final String ? content;
  final String ? thumbnailURL;
  final bool isUserArticle;
  final String ? createdAt;
  final String ? firestoreId;
  final String ? userId;

  const ArticleEntity({
    this.id,
    this.author,
    this.title,
    this.description,
    this.url,
    this.urlToImage,
    this.publishedAt,
    this.content,
    this.thumbnailURL,
    this.isUserArticle = false,
    this.createdAt,
    this.firestoreId,
    this.userId,
  });

  String get displayImageUrl {
    if (urlToImage != null && urlToImage!.isNotEmpty) return urlToImage!;
    if (thumbnailURL != null && thumbnailURL!.isNotEmpty) return thumbnailURL!;
    return kDefaultImage;
  }

  ArticleEntity copyWith({
    int? id,
    String? author,
    String? title,
    String? description,
    String? url,
    String? urlToImage,
    String? publishedAt,
    String? content,
    String? thumbnailURL,
    bool? isUserArticle,
    String? createdAt,
    String? firestoreId,
    String? userId,
  }) => ArticleEntity(
    id: id ?? this.id,
    author: author ?? this.author,
    title: title ?? this.title,
    description: description ?? this.description,
    url: url ?? this.url,
    urlToImage: urlToImage ?? this.urlToImage,
    publishedAt: publishedAt ?? this.publishedAt,
    content: content ?? this.content,
    thumbnailURL: thumbnailURL ?? this.thumbnailURL,
    isUserArticle: isUserArticle ?? this.isUserArticle,
    createdAt: createdAt ?? this.createdAt,
    firestoreId: firestoreId ?? this.firestoreId,
    userId: userId ?? this.userId,
  );

  @override
  List < Object ? > get props {
    return [
      id,
      author,
      title,
      description,
      url,
      urlToImage,
      publishedAt,
      content,
      thumbnailURL,
      isUserArticle,
      createdAt,
      firestoreId,
      userId,
    ];
  }
}
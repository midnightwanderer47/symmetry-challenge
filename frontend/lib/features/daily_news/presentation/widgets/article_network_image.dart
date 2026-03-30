import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Displays a [CachedNetworkImage] when [imageUrl] is non-null, or a
/// theme-aware local placeholder when the article has no uploaded image.
class ArticleNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ArticleNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final placeholderColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;

    if (imageUrl == null) {
      return _placeholder(placeholderColor, icon: Icons.image_outlined);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      progressIndicatorBuilder: (_, __, ___) =>
          _placeholder(placeholderColor, loading: true),
      errorWidget: (_, __, ___) =>
          _placeholder(placeholderColor, icon: Icons.error_outline),
    );
  }

  Widget _placeholder(
    Color color, {
    IconData? icon,
    bool loading = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: loading
            ? const CupertinoActivityIndicator()
            : Icon(icon, color: Colors.grey),
      ),
    );
  }
}

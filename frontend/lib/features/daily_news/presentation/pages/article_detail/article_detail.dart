import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../../core/formatting/date_formatter.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/article.dart';
import '../../bloc/article/delete/delete_article_cubit.dart';
import '../../bloc/article/delete/delete_article_state.dart';
import '../../bloc/article/local/local_article_bloc.dart';
import '../../bloc/article/local/local_article_event.dart';
import '../../widgets/delete_article_dialog.dart';
import '../../widgets/markdown_body_widget.dart';

class ArticleDetailsView extends HookWidget {
  final ArticleEntity? article;

  const ArticleDetailsView({Key? key, this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<LocalArticleBloc>()),
        BlocProvider(create: (_) => sl<DeleteArticleCubit>()),
      ],
      child: BlocListener<DeleteArticleCubit, DeleteArticleState>(
        listener: (context, state) {
          if (state is DeleteArticleSuccess) {
            Navigator.pop(context);
          } else if (state is DeleteArticleFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
          appBar: _buildAppBar(),
          body: _buildBody(),
          floatingActionButton: _buildFloatingActionButton(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid != null &&
        article?.userId == currentUid &&
        article?.firestoreId != null;

    return AppBar(
      leading: Builder(
        builder: (context) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onBackButtonTapped(context),
          child: const Icon(Ionicons.chevron_back),
        ),
      ),
      actions: isOwner
          ? [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _onDeleteTapped(context),
                ),
              ),
            ]
          : null,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildArticleTitleAndDate(),
          _buildArticleImage(),
          _buildArticleDescription(),
        ],
      ),
    );
  }

  Widget _buildArticleTitleAndDate() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            article!.title!,
            style: const TextStyle(
                fontFamily: 'Butler',
                fontSize: 20,
                fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 14),
          // DateTime
          Builder(builder: (context) {
            return Row(
              children: [
                const Icon(Ionicons.time_outline, size: 16),
                const SizedBox(width: 4),
                Text(
                  formatPublishedAt(
                    article!.publishedAt,
                    article!.createdAt,
                    Localizations.localeOf(context),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildArticleImage() {
    return Container(
      width: double.maxFinite,
      height: 250,
      margin: const EdgeInsets.only(top: 14),
      child: Builder(
        builder: (context) {
          final placeholderColor =
              Theme.of(context).colorScheme.surfaceContainerHighest;
          return CachedNetworkImage(
            imageUrl: article!.displayImageUrl,
            width: double.maxFinite,
            height: 250,
            fit: BoxFit.cover,
            progressIndicatorBuilder: (context, url, progress) => Container(
              color: placeholderColor,
              child: const Center(child: CupertinoActivityIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: placeholderColor,
              child: const Center(child: Icon(Icons.error_outline)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticleDescription() {
    final content =
        '${article!.description ?? ''}\n\n${article!.content ?? ''}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: ArticleMarkdownBody(content: content),
    );
  }

  Widget _buildFloatingActionButton() {
    return Builder(
      builder: (context) => FloatingActionButton(
        onPressed: () => _onFloatingActionButtonPressed(context),
        child: Icon(Ionicons.bookmark,
            color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }

  void _onBackButtonTapped(BuildContext context) {
    Navigator.pop(context);
  }

  void _onFloatingActionButtonPressed(BuildContext context) {
    BlocProvider.of<LocalArticleBloc>(context).add(SaveArticle(article!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        content: Text('Article saved successfully.',
            style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface)),
      ),
    );
  }

  void _onDeleteTapped(BuildContext context) {
    showDeleteArticleConfirmation(
      context,
      () => context.read<DeleteArticleCubit>().deleteArticle(article!.firestoreId!),
    );
  }
}

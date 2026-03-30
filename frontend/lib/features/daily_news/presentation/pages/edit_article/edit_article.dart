import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/edit/edit_article_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/edit/edit_article_state.dart';
import 'package:news_app_clean_architecture/injection_container.dart';

class EditArticleView extends StatefulWidget {
  final ArticleEntity article;

  const EditArticleView({Key? key, required this.article}) : super(key: key);

  @override
  State<EditArticleView> createState() => _EditArticleViewState();
}

class _EditArticleViewState extends State<EditArticleView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contentController;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article.title ?? '');
    _authorController =
        TextEditingController(text: widget.article.author ?? '');
    _descriptionController =
        TextEditingController(text: widget.article.description ?? '');
    _contentController =
        TextEditingController(text: widget.article.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = picked);
    }
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final updatedArticle = widget.article.copyWith(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      description: _descriptionController.text.trim(),
      content: _contentController.text.trim(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    context.read<EditArticleCubit>().updateArticle(
          updatedArticle,
          thumbnailFilePath: _imageFile?.path,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EditArticleCubit>(),
      child: BlocConsumer<EditArticleCubit, EditArticleState>(
        listener: (context, state) {
          if (state is EditArticleSuccess) {
            Navigator.pop(context, true);
          } else if (state is EditArticleFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is EditArticleLoading;
          final onSurface = Theme.of(context).colorScheme.onSurface;
          final existingImageUrl =
              widget.article.thumbnailURL?.isNotEmpty == true
                  ? widget.article.thumbnailURL
                  : (widget.article.urlToImage?.isNotEmpty == true
                      ? widget.article.urlToImage
                      : null);

          return PopScope(
            canPop: !isLoading,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Edit Article'),
              ),
              body: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration:
                                const InputDecoration(labelText: 'Title *'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _authorController,
                            decoration:
                                const InputDecoration(labelText: 'Author *'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            decoration:
                                const InputDecoration(labelText: 'Description'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Content *',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _contentController,
                            decoration:
                                const InputDecoration.collapsed(hintText: ''),
                            minLines: 6,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            keyboardType: TextInputType.multiline,
                            stylusHandwritingEnabled: false,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          Divider(
                              height: 1,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.38)),
                          const SizedBox(height: 8),
                          Text.rich(
                            TextSpan(
                              style: TextStyle(
                                  fontSize: 12,
                                  color: onSurface.withValues(
                                      alpha: onSurface.a * 0.5)),
                              children: const [
                                TextSpan(text: 'Supported: '),
                                TextSpan(
                                    text: '# Heading',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text:
                                        ', **bold**, _italic_, - lists, line breaks'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Change Thumbnail'),
                          ),
                          if (_imageFile != null) ...[
                            const SizedBox(height: 8),
                            Semantics(
                              label: 'Tap preview to change thumbnail',
                              child: InkWell(
                                onTap: _pickImage,
                                borderRadius: BorderRadius.circular(8),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_imageFile!.path),
                                        height: 180,
                                        fit: BoxFit.cover,
                                        cacheWidth: 240,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to change',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: onSurface.withValues(
                                              alpha: onSurface.a * 0.5)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else if (existingImageUrl != null) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _pickImage,
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: existingImageUrl,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to change',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: onSurface.withValues(
                                            alpha: onSurface.a * 0.5)),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'No thumbnail — tap "Change Thumbnail" to add one',
                                style: TextStyle(
                                    color: onSurface.withValues(
                                        alpha: onSurface.a * 0.5)),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed:
                                isLoading ? null : () => _submit(context),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isLoading)
                    Positioned.fill(
                      child: Semantics(
                        label: 'Saving article, please wait',
                        liveRegion: true,
                        child: IgnorePointer(
                          child: Container(
                            color: Colors.black54,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Saving...',
                                    style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(color: Colors.white) ??
                                        const TextStyle(
                                            fontSize: 20, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:news_app_clean_architecture/features/daily_news/domain/entities/article.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/upload/article_upload_cubit.dart';
import 'package:news_app_clean_architecture/features/daily_news/presentation/bloc/article/upload/article_upload_state.dart';
import 'package:news_app_clean_architecture/injection_container.dart';

class UploadArticleView extends StatefulWidget {
  @visibleForTesting
  final Stream<User?>? authStateStream;

  const UploadArticleView({Key? key, this.authStateStream}) : super(key: key);

  @override
  State<UploadArticleView> createState() => _UploadArticleViewState();
}

class _UploadArticleViewState extends State<UploadArticleView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  XFile? _imageFile;

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

    final article = ArticleEntity(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      description: _descriptionController.text.trim(),
      content: _contentController.text.trim(),
      publishedAt: DateTime.now().toIso8601String(),
    );

    context.read<ArticleUploadCubit>().upload(
          article,
          thumbnailFilePath: _imageFile?.path,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ArticleUploadCubit>(),
      child: BlocConsumer<ArticleUploadCubit, ArticleUploadState>(
        listener: (context, state) {
          if (state is ArticleUploadSuccess) {
            Navigator.pop(context, true);
          } else if (state is ArticleUploadFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ArticleUploadLoading;
          final onSurface = Theme.of(context).colorScheme.onSurface;
          return PopScope(
            canPop: !isLoading,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Upload Article'),
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
                      decoration: const InputDecoration(labelText: 'Title *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(labelText: 'Author *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(labelText: 'Content *'),
                      minLines: 10,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 12,
                            color: onSurface.withValues(alpha: onSurface.a * 0.5)),
                        children: const [
                          TextSpan(text: 'Supported: '),
                          TextSpan(text: '# Heading', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: ', **bold**, _italic_, - lists, line breaks'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Thumbnail'),
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
                                style: TextStyle(fontSize: 12,
                                    color: onSurface.withValues(alpha: onSurface.a * 0.5)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'No thumbnail selected — placeholder will be used',
                          style: TextStyle(
                              color: onSurface.withValues(alpha: onSurface.a * 0.5)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    StreamBuilder<User?>(
                      stream: widget.authStateStream ?? FirebaseAuth.instance.authStateChanges(),
                      builder: (context, authSnapshot) {
                        final isAuthenticated = authSnapshot.data != null;
                        return ElevatedButton(
                          onPressed: (isLoading || !isAuthenticated) ? null : () => _submit(context),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Publish Article'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Positioned.fill(
                child: Semantics(
                  label: 'Publishing article, please wait',
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
                              'Publishing...',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)
                                  ?? const TextStyle(fontSize: 20, color: Colors.white),
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

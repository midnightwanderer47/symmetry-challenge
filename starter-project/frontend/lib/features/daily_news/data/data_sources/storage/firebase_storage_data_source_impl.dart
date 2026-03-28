import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'firebase_storage_data_source.dart';

class FirebaseStorageDataSourceImpl implements FirebaseStorageDataSource {
  final FirebaseStorage _storage;

  FirebaseStorageDataSourceImpl({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadThumbnail(String filePath) async {
    try {
      final fileName = '${const Uuid().v4()}${p.extension(filePath)}';
      final ref = _storage.ref().child('media/articles/$fileName');
      final snapshot = await ref.putFile(File(filePath));
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException {
      rethrow;
    }
  }
}

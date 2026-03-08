import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileStorageService {
  ProfileStorageService({FirebaseStorage? storage, ImagePicker? imagePicker})
      : _storage = storage ?? FirebaseStorage.instance,
        _imagePicker = imagePicker ?? ImagePicker();

  final FirebaseStorage _storage;
  final ImagePicker _imagePicker;

  Reference _avatarRef(String uid) => _storage.ref('users/$uid/avatar.jpg');

  /// Pick an image from the given source.
  /// Returns null if the user cancels.
  Future<XFile?> pickImage(ImageSource source) async {
    return _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
  }

  /// Upload avatar image bytes and return the download URL.
  /// Deletes the old avatar first to avoid orphaned files.
  Future<String> uploadAvatar(String uid, Uint8List bytes) async {
    final ref = _avatarRef(uid);

    // Delete old avatar (best-effort)
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }

    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Delete the user's avatar from Storage.
  Future<void> deleteAvatar(String uid) async {
    try {
      await _avatarRef(uid).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}

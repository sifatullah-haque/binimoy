import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  Future<String> uploadImage(File imageFile) async {
    try {
      // Create a unique filename
      final fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';

      // Simplified path - just use root level folder
      final storageRef = _storage.ref();
      final imageRef = storageRef.child('images/$fileName');

      print('Starting Firebase upload to simplified path: images/$fileName');
      print(
          'Image file exists: ${imageFile.existsSync()}, Size: ${imageFile.lengthSync()} bytes');

      // Simple metadata with content type
      final contentType =
          'image/${path.extension(imageFile.path).replaceFirst('.', '')}';
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {'source': 'Binimoy app'},
      );

      print('Using content type: $contentType');

      // Start the upload task
      final uploadTask = imageRef.putFile(imageFile, metadata);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      }, onError: (e) {
        print('Upload stream error: $e');
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      print('Upload task completed, state: ${snapshot.state}');

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Firebase upload successful, URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}, message: ${e.message}');

        // Handle specific error cases
        if (e.code == 'object-not-found') {
          // This could happen if storage rules prevent access
          print('Storage access denied. Check Firebase Storage rules.');
        }
      }
      rethrow;
    }
  }
}

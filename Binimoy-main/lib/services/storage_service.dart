import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageService {
  final cloudinary =
      CloudinaryPublic('your-cloud-name', 'your-upload-preset', cache: false);
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  Future<String> uploadImage(File imageFile) async {
    try {
      // Try Cloudinary first
      try {
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            imageFile.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        print('Cloudinary upload successful: ${response.secureUrl}');
        return response.secureUrl;
      } catch (cloudinaryError) {
        print('Cloudinary upload failed: $cloudinaryError, trying Firebase...');
        // Fall back to Firebase Storage
        final fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';
        final ref = _storage.ref().child('profile_images/$fileName');
        final uploadTask = ref.putFile(imageFile);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print('Firebase upload successful: $downloadUrl');
        return downloadUrl;
      }
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }
}

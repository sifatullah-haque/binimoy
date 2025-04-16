import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class StorageService {
  final cloudinary =
      CloudinaryPublic('dwdtzllyy', 'Binimoy_saree_image', cache: false);

  Future<String> uploadImage(File imageFile,
      {Function(double)? onProgress}) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'profile_images',
        ),
        uploadPreset: 'Binimoy_saree_image',
        onProgress: (count, total) {
          if (onProgress != null) {
            onProgress(count / total);
          }
        },
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      throw 'Failed to upload image: ${e.toString()}';
    }
  }
}

import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class StorageService {
  final cloudinary = CloudinaryPublic('dwdtzllyy', 'Binimoy_saree_image', cache: false);

  Future<String> uploadImage(File imageFile) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'profile_images',
        ),
        // Using uploadPreset instead of transformations
        // The transformations should be configured in your Cloudinary upload preset
        uploadPreset: 'Binimoy_saree_image',
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      throw 'Failed to upload image: ${e.toString()}';
    }
  }
}
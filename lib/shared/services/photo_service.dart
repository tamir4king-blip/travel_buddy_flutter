import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Copy to app documents directory for persistence
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(path.join(appDir.path, 'travel_buddy_photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      final savedPath = path.join(photosDir.path, fileName);
      await File(image.path).copy(savedPath);

      return savedPath;
    } catch (e) {
      return null;
    }
  }
}

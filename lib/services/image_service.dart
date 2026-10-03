import 'package:image/image.dart' as img;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ProcessedImages {
  final String? thumbB64;
  final List<String> imagesB64;

  const ProcessedImages({this.thumbB64, required this.imagesB64});
}

/// Handles picking, compressing and encoding listing images.
/// Images are stored as base64 in Firestore because Cloud Storage
/// requires a billing account on new Firebase projects (see README).
class ImageService {
  static const int maxImages = 5;

  Future<List<XFile>> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      limit: maxImages,
      maxWidth: 1000,
      imageQuality: 70,
    );
    return picked;
  }

  Future<ProcessedImages?> process(List<XFile> files) async {
    if (files.isEmpty) return null;
    final full = <String>[];
    String? thumb;
    for (final f in files) {
      final bytes = await f.readAsBytes();
      full.add(base64Encode(bytes));
      if (thumb == null) {
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final resized = img.copyResize(decoded, width: 480);
          thumb = base64Encode(img.encodeJpg(resized, quality: 55));
        }
      }
    }
    return ProcessedImages(thumbB64: thumb, imagesB64: full);
  }
}

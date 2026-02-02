import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageCompressService {
  static Future<File?> compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    final String targetPath =
        '$path/${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Get the file extension
    final String extension = p.extension(file.path).toLowerCase();

    // Convert png to jpg because flutter_image_compress works best with jpg
    CompressFormat format = CompressFormat.jpeg;
    if (extension == '.png') {
      format = CompressFormat.png;
    } else if (extension == '.webp') {
      format = CompressFormat.webp;
    }

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: 800,
      minHeight: 800,
      quality: 70, // Adjust quality as needed (0-100)
      format: format,
    );

    if (result == null) return null;
    return File(result.path);
  }
}

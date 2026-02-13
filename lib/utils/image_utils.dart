/// Image processing utilities
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageUtils {
  /// Flip image horizontally (normalize front camera mirror)
  static img.Image? flipHorizontal(img.Image? image) {
    if (image == null) return null;
    return img.flipHorizontal(image);
  }

  /// Encode image to JPG bytes
  static List<int> encodeToJpg(img.Image image, [int quality = 85]) {
    return img.encodeJpg(image, quality: quality);
  }

  /// Decode image from bytes
  static img.Image? decodeFromBytes(Uint8List bytes) {
    return img.decodeImage(bytes);
  }
}
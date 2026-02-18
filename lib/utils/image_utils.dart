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

  /// Resize image to specific dimensions
  static img.Image? resize(img.Image? image, int width, int height) {
    if (image == null) return null;
    return img.copyResize(image, width: width, height: height);
  }

  /// Crop image to center with specific dimensions (no distortion)
  static img.Image? cropToCenter(img.Image? image, int width, int height) {
    if (image == null) return null;
    
    int x = (image.width - width) ~/ 2;
    int y = (image.height - height) ~/ 2;
    
    // Ensure crop coordinates are valid
    x = x < 0 ? 0 : x;
    y = y < 0 ? 0 : y;
    int w = width > image.width ? image.width : width;
    int h = height > image.height ? image.height : height;
    
    return img.copyCrop(image, x, y, w, h);
  }

  /// Fit & crop to target dimensions maintaining aspect ratio
  /// Strategy: Resize to fit in target box, then crop from center
  static img.Image? fitAndCrop(img.Image? image, int width, int height) {
    if (image == null) return null;
    
    // Calculate scale factor based on width and height constraints
    double scaleW = width / image.width;
    double scaleH = height / image.height;
    
    // Use the larger scale to ensure we can fill the frame (crop if needed)
    // This means we'll get the full width and crop from height if needed
    double scale = scaleW;
    
    int newWidth = width;
    int newHeight = (image.height * scale).toInt();
    
    // Resize image
    var resized = img.copyResize(image, width: newWidth, height: newHeight);
    
    // If height is still less than target, we have an issue
    // In this case, use the larger scale to match height instead
    if (newHeight < height) {
      scale = scaleH;
      newWidth = (image.width * scale).toInt();
      newHeight = height;
      resized = img.copyResize(image, width: newWidth, height: newHeight);
    }
    
    // Crop from center (both horizontally if width overshoots, vertically for height)
    int cropX = (newWidth - width) ~/ 2;
    // Crop 70% dari atas, 30% dari bawah (more bottom)
    int cropY = ((newHeight - height) * 0.7).toInt();
    
    // Ensure valid crop coordinates
    if (cropX < 0) cropX = 0;
    if (cropY < 0) cropY = 0;
    
    int cropWidth = width > resized.width ? resized.width : width;
    int cropHeight = height > resized.height ? resized.height : height;
    
    return img.copyCrop(resized, cropX, cropY, cropWidth, cropHeight);
  }
}
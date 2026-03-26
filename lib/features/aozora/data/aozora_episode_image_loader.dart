import 'dart:typed_data';
import 'dart:ui' as ui;

class AozoraEpisodeImageLoader {
  AozoraEpisodeImageLoader(Map<String, Uint8List> images)
    : _images = _buildIndex(images);

  final Map<String, Uint8List> _images;

  Future<ui.Image?> loadImage(String imagePath) async {
    if (imagePath.trim().isEmpty) {
      return null;
    }

    final bytes = _resolveBytes(imagePath);
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    try {
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        return frame.image;
      } finally {
        codec.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  Uint8List? _resolveBytes(String imagePath) {
    final normalizedPath = _normalizeKey(imagePath);
    if (normalizedPath.isEmpty) {
      return null;
    }

    final byPath = _images[normalizedPath];
    if (byPath != null) {
      return byPath;
    }

    final segments = normalizedPath.split('/');
    if (segments.isEmpty) {
      return null;
    }
    return _images[segments.last];
  }

  static Map<String, Uint8List> _buildIndex(Map<String, Uint8List> source) {
    final index = <String, Uint8List>{};
    source.forEach((rawName, bytes) {
      final normalizedName = _normalizeKey(rawName);
      if (normalizedName.isEmpty || bytes.isEmpty) {
        return;
      }
      index.putIfAbsent(normalizedName, () => bytes);
      final segments = normalizedName.split('/');
      if (segments.isNotEmpty) {
        index.putIfAbsent(segments.last, () => bytes);
      }
    });
    return index;
  }

  static String _normalizeKey(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final uriDecoded = Uri.decodeFull(trimmed);
    final withoutQuery = uriDecoded.split('?').first.split('#').first;
    var normalized = withoutQuery.replaceAll('\\', '/');
    while (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }
    while (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    return normalized.toLowerCase();
  }
}

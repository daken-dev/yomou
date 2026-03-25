import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:yomou/core/network/dio_provider.dart';

final narouEpisodeImageCacheProvider = Provider<NarouEpisodeImageCache>((ref) {
  return NarouEpisodeImageCache(ref.watch(dioProvider));
});

class NarouEpisodeImageCache {
  NarouEpisodeImageCache(this._dio);

  final Dio _dio;
  final Map<String, Future<File>> _pendingFiles = <String, Future<File>>{};

  Future<ui.Image?> loadImage(String imageUrl) async {
    if (imageUrl.isEmpty) {
      return null;
    }

    try {
      final file = await _pendingFiles.putIfAbsent(
        imageUrl,
        () => _ensureCachedFile(imageUrl),
      );
      final bytes = await file.readAsBytes();
      return _decode(bytes);
    } catch (_) {
      return null;
    } finally {
      _pendingFiles.remove(imageUrl);
    }
  }

  Future<File> _ensureCachedFile(String imageUrl) async {
    final directory = await _cacheDirectory();
    final extension = _fileExtension(imageUrl);
    final file = File(
      path.join(directory.path, '${_hashUrl(imageUrl)}$extension'),
    );
    if (await file.exists()) {
      return file;
    }

    final response = await _dio.get<List<int>>(
      imageUrl,
      options: Options(
        responseType: ResponseType.bytes,
        headers: <String, Object>{
          'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
          'Referer': imageUrl,
          'User-Agent':
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
        },
      ),
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('Image download returned empty bytes.');
    }

    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Directory> _cacheDirectory() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(path.join(root.path, 'narou_episode_images'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<ui.Image> _decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  String _fileExtension(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    final value = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : '';
    final extension = path.extension(value);
    if (extension.isEmpty || extension.length > 8) {
      return '.img';
    }
    return extension;
  }

  String _hashUrl(String value) {
    var hash = 0xcbf29ce484222325;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:jis0208/jis0208.dart';
import 'package:yomou/features/aozora/data/aozora_text_normalizer.dart';

class AozoraTextClient {
  AozoraTextClient(this._dio);

  final Dio _dio;

  Future<AozoraTextFile> fetchText(String zipUrl) async {
    final response = await _dio.get<List<int>>(
      zipUrl,
      options: Options(
        responseType: ResponseType.bytes,
        headers: const <String, Object>{'Accept': 'application/zip,*/*'},
      ),
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('青空本文zipのダウンロードに失敗しました。');
    }

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final textFile = archive.files.firstWhere(
      (file) => !file.isFile ? false : file.name.toLowerCase().endsWith('.txt'),
      orElse: () => throw const FormatException('青空本文テキストが見つかりません。'),
    );

    final textBytes = textFile.content as List<int>;
    final decoded = _decodeText(textBytes);
    final normalized = AozoraTextNormalizer.stripIntroBlock(decoded);
    return AozoraTextFile(
      fileName: textFile.name,
      text: normalized,
      images: _collectImages(archive),
    );
  }

  String _decodeText(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return Windows31JCodec().decode(bytes);
    }
  }

  Map<String, Uint8List> _collectImages(Archive archive) {
    final images = <String, Uint8List>{};
    for (final file in archive.files) {
      if (!file.isFile || !_isImageFile(file.name)) {
        continue;
      }
      final bytes = _extractBytes(file);
      if (bytes.isEmpty) {
        continue;
      }
      final normalizedName = _normalizePath(file.name);
      if (normalizedName.isEmpty) {
        continue;
      }
      images.putIfAbsent(normalizedName, () => bytes);
      final segments = normalizedName.split('/');
      if (segments.isNotEmpty) {
        images.putIfAbsent(segments.last, () => bytes);
      }
    }
    return images;
  }

  bool _isImageFile(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  Uint8List _extractBytes(ArchiveFile file) {
    return file.content;
  }

  String _normalizePath(String value) {
    final uriDecoded = Uri.decodeFull(value.trim());
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

class AozoraTextFile {
  const AozoraTextFile({
    required this.fileName,
    required this.text,
    this.images = const <String, Uint8List>{},
  });

  final String fileName;
  final String text;
  final Map<String, Uint8List> images;
}

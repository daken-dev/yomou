import 'dart:convert';

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
        headers: const <String, Object>{
          'Accept': 'application/zip,*/*',
        },
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
    return AozoraTextFile(fileName: textFile.name, text: normalized);
  }

  String _decodeText(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return Windows31JCodec().decode(bytes);
    }
  }
}

class AozoraTextFile {
  const AozoraTextFile({required this.fileName, required this.text});

  final String fileName;
  final String text;
}

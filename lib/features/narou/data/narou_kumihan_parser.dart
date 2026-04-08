import 'package:kumihan/kumihan.dart' as kumi;
import 'package:yomou/features/downloads/data/narou_web_client.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

class NarouKumihanParser {
  const NarouKumihanParser();

  kumi.Document parseEpisode(
    NarouEpisodePage page, {
    ReaderSettings settings = const ReaderSettings.defaults(),
  }) {
    final paragraphs = <List<kumi.AstToken>>[
      ..._buildTitleHeader(page),
      ..._buildSections(page, settings: settings),
    ];

    final normalizedParagraphs = _trimEdgeBlankParagraphs(
      paragraphs.map(_normalizeParagraph).toList(growable: false),
    );

    if (normalizedParagraphs.isEmpty) {
      normalizedParagraphs.add(<kumi.AstToken>[
        const kumi.AstText('本文がありません。'),
      ]);
    }

    return kumi.Document.fromAst(
      _joinParagraphs(normalizedParagraphs),
      headerTitle: _headerTitle(page),
    );
  }

  List<List<kumi.AstToken>> _buildSections(
    NarouEpisodePage page, {
    required ReaderSettings settings,
  }) {
    final sections = <List<List<kumi.AstToken>>>[];

    if (settings.showPreface) {
      final preface = _parseSectionParagraphs(
        htmlFragment: page.prefaceHtml,
        fallbackText: page.preface,
        baseUrl: page.url,
      );
      if (preface.isNotEmpty) {
        sections.add(preface);
      }
    }

    final body = _parseSectionParagraphs(
      htmlFragment: page.bodyHtml,
      fallbackText: page.body,
      baseUrl: page.url,
    );
    if (body.isNotEmpty) {
      sections.add(body);
    }

    if (settings.showAfterword) {
      final afterword = _parseSectionParagraphs(
        htmlFragment: page.afterwordHtml,
        fallbackText: page.afterword,
        baseUrl: page.url,
      );
      if (afterword.isNotEmpty) {
        sections.add(afterword);
      }
    }

    final paragraphs = <List<kumi.AstToken>>[];
    for (var index = 0; index < sections.length; index += 1) {
      if (index > 0) {
        paragraphs.add(const <kumi.AstToken>[kumi.AstText('――――')]);
      }
      paragraphs.addAll(sections[index]);
    }
    return paragraphs;
  }

  List<List<kumi.AstToken>> _buildTitleHeader(NarouEpisodePage page) {
    final paragraphs = <List<kumi.AstToken>>[];
    final isShortStory =
        page.sequenceTotal != null &&
        page.sequenceTotal == 1 &&
        page.prevUrl == null &&
        page.nextUrl == null;
    final isFirstEpisode = page.sequenceCurrent == 1;
    final novelTitle = (page.novelTitle ?? '').trim();
    final authorName = (page.authorName ?? '').trim();
    final episodeTitle = (page.title ?? '').trim();

    if (isShortStory) {
      if (novelTitle.isNotEmpty) {
        paragraphs.add(
          _headingParagraph(novelTitle, kumi.AstHeadingLevel.large),
        );
      }
      if (authorName.isNotEmpty) {
        paragraphs.add(const <kumi.AstToken>[]);
        paragraphs.add(<kumi.AstToken>[kumi.AstText(authorName)]);
      }
    } else if (isFirstEpisode) {
      if (novelTitle.isNotEmpty) {
        paragraphs.add(
          _headingParagraph(novelTitle, kumi.AstHeadingLevel.large),
        );
      }
      if (authorName.isNotEmpty) {
        paragraphs.add(const <kumi.AstToken>[]);
        paragraphs.add(<kumi.AstToken>[kumi.AstText(authorName)]);
      }
      if (episodeTitle.isNotEmpty) {
        paragraphs.add(const <kumi.AstToken>[]);
        paragraphs.add(
          _headingParagraph(episodeTitle, kumi.AstHeadingLevel.medium),
        );
      }
    } else if (episodeTitle.isNotEmpty) {
      paragraphs.add(
        _headingParagraph(episodeTitle, kumi.AstHeadingLevel.medium),
      );
    }

    if (paragraphs.isNotEmpty) {
      paragraphs.add(const <kumi.AstToken>[]);
      paragraphs.add(const <kumi.AstToken>[]);
    }

    return paragraphs;
  }

  List<kumi.AstToken> _headingParagraph(
    String text,
    kumi.AstHeadingLevel level,
  ) {
    return <kumi.AstToken>[
      kumi.AstHeading(
        boundary: kumi.AstRangeBoundary.start,
        form: kumi.AstHeadingForm.standalone,
        level: level,
      ),
      kumi.AstText(text),
      kumi.AstHeading(
        boundary: kumi.AstRangeBoundary.end,
        form: kumi.AstHeadingForm.standalone,
        level: level,
      ),
    ];
  }

  List<List<kumi.AstToken>> _parseSectionParagraphs({
    required String? htmlFragment,
    required String? fallbackText,
    required String baseUrl,
  }) {
    final normalizedHtml = htmlFragment?.trim() ?? '';
    if (normalizedHtml.isNotEmpty) {
      final document = const kumi.HtmlParser().parse(normalizedHtml);
      return _trimEdgeBlankParagraphs(
        _splitParagraphs(
          _resolveUrlTokens(document.ast, baseUrl),
        ).map(_normalizeParagraph).toList(growable: false),
      );
    }

    final normalizedText = fallbackText?.trim() ?? '';
    if (normalizedText.isEmpty) {
      return const <List<kumi.AstToken>>[];
    }

    return _trimEdgeBlankParagraphs(
      normalizedText
          .split('\n')
          .map(_plainParagraphFromText)
          .map(_normalizeParagraph)
          .toList(growable: false),
    );
  }

  List<kumi.AstToken> _resolveUrlTokens(
    Iterable<kumi.AstToken> tokens,
    String baseUrl,
  ) {
    return tokens
        .map((token) {
          return switch (token) {
            kumi.AstLink(boundary: final boundary, target: final target) =>
              kumi.AstLink(
                boundary: boundary,
                target: absoluteUrl(target, baseUrl),
              ),
            kumi.AstImage(
              description: final description,
              fileName: final fileName,
              size: final size,
              hasCaption: final hasCaption,
            ) =>
              kumi.AstImage(
                description: description,
                fileName: absoluteUrl(fileName, baseUrl) ?? fileName,
                size: size,
                hasCaption: hasCaption,
              ),
            _ => token,
          };
        })
        .toList(growable: false);
  }

  List<List<kumi.AstToken>> _splitParagraphs(Iterable<kumi.AstToken> tokens) {
    final paragraphs = <List<kumi.AstToken>>[];
    var current = <kumi.AstToken>[];

    for (final token in tokens) {
      if (token is kumi.AstNewLine) {
        paragraphs.add(current);
        current = <kumi.AstToken>[];
        continue;
      }
      current.add(token);
    }

    paragraphs.add(current);
    return paragraphs;
  }

  List<kumi.AstToken> _joinParagraphs(
    Iterable<List<kumi.AstToken>> paragraphs,
  ) {
    final tokens = <kumi.AstToken>[];
    var first = true;
    for (final paragraph in paragraphs) {
      if (!first) {
        tokens.add(const kumi.AstNewLine());
      }
      first = false;
      tokens.addAll(paragraph);
    }
    return tokens;
  }

  List<kumi.AstToken> _plainParagraphFromText(String rawText) {
    final normalized = rawText
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'[\t\r]+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return const <kumi.AstToken>[];
    }
    return _normalizeTextTokens(normalized);
  }

  List<kumi.AstToken> _normalizeParagraph(List<kumi.AstToken> paragraph) {
    if (_isBlankParagraph(paragraph)) {
      return const <kumi.AstToken>[];
    }
    final plainText = _plainText(paragraph).trim();
    if (plainText.isNotEmpty && _isDividerText(plainText)) {
      return const <kumi.AstToken>[kumi.AstText('――――')];
    }
    return paragraph;
  }

  bool _isBlankParagraph(List<kumi.AstToken> paragraph) {
    if (paragraph.isEmpty) {
      return true;
    }
    final plainText = _plainText(paragraph);
    return plainText.replaceAll(RegExp(r'[\s　]+'), '').isEmpty;
  }

  List<List<kumi.AstToken>> _trimEdgeBlankParagraphs(
    List<List<kumi.AstToken>> paragraphs,
  ) {
    final trimmed = List<List<kumi.AstToken>>.from(paragraphs);
    while (trimmed.isNotEmpty && _isBlankParagraph(trimmed.first)) {
      trimmed.removeAt(0);
    }
    while (trimmed.isNotEmpty && _isBlankParagraph(trimmed.last)) {
      trimmed.removeLast();
    }
    return trimmed;
  }

  bool _isDividerText(String text) {
    final normalized = text
        .replaceAll('＊', '*')
        .replaceAll('＝', '=')
        .replaceAll('＿', '_')
        .replaceAll(RegExp(r'[ー―−－]'), '-');
    return RegExp(r'^([*=_-])\1{3,}$').hasMatch(normalized);
  }

  String _plainText(List<kumi.AstToken> tokens) {
    final buffer = StringBuffer();
    for (final token in tokens) {
      switch (token) {
        case kumi.AstText(text: final text):
          buffer.write(text);
        case kumi.AstAttachedText(boundary: final boundary)
            when boundary == kumi.AstRangeBoundary.start:
        case kumi.AstAttachedText():
        case kumi.AstStyledText():
        case kumi.AstLink():
        case kumi.AstInlineDecoration():
        case kumi.AstHeading():
          break;
        default:
          return '';
      }
    }
    return buffer.toString();
  }

  List<kumi.AstToken> _normalizeTextTokens(String text) {
    final tokens = <kumi.AstToken>[];
    final buffer = StringBuffer();
    var index = 0;

    while (index < text.length) {
      final digitRunLength = _digitRunLength(text, index);
      if (digitRunLength == 2) {
        if (buffer.isNotEmpty) {
          tokens.add(kumi.AstText(buffer.toString()));
          buffer.clear();
        }
        tokens.add(
          const kumi.AstInlineDecoration(
            boundary: kumi.AstRangeBoundary.start,
            kind: kumi.AstInlineDecorationKind.tatechuyoko,
          ),
        );
        tokens.add(
          kumi.AstText(_toHalfWidthDigits(text.substring(index, index + 2))),
        );
        tokens.add(
          const kumi.AstInlineDecoration(
            boundary: kumi.AstRangeBoundary.end,
            kind: kumi.AstInlineDecorationKind.tatechuyoko,
          ),
        );
        index += 2;
        continue;
      }
      if (digitRunLength > 0) {
        buffer.write(text.substring(index, index + digitRunLength));
        index += digitRunLength;
        continue;
      }
      buffer.writeCharCode(text.codeUnitAt(index));
      index += 1;
    }

    if (buffer.isNotEmpty) {
      tokens.add(kumi.AstText(buffer.toString()));
    }
    return tokens;
  }

  int _digitRunLength(String text, int start) {
    var index = start;
    while (index < text.length && _isDigitCodeUnit(text.codeUnitAt(index))) {
      index += 1;
    }
    return index - start;
  }

  bool _isDigitCodeUnit(int codeUnit) {
    return (codeUnit >= 0x30 && codeUnit <= 0x39) ||
        (codeUnit >= 0xFF10 && codeUnit <= 0xFF19);
  }

  String _toHalfWidthDigits(String text) {
    final buffer = StringBuffer();
    for (final codeUnit in text.codeUnits) {
      if (codeUnit >= 0xFF10 && codeUnit <= 0xFF19) {
        buffer.writeCharCode(codeUnit - 0xFEE0);
        continue;
      }
      buffer.writeCharCode(codeUnit);
    }
    return buffer.toString();
  }

  String _headerTitle(NarouEpisodePage page) {
    final parts = <String>[
      if ((page.novelTitle ?? '').isNotEmpty) page.novelTitle!,
      if ((page.title ?? '').isNotEmpty) page.title!,
    ];
    return parts.join(' / ');
  }
}

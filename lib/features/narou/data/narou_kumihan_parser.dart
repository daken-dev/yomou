import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;
import 'package:kumihan/kumihan.dart';
import 'package:yomou/features/downloads/data/narou_web_client.dart';

class NarouKumihanParser {
  const NarouKumihanParser();

  KumihanDocument parseEpisode(NarouEpisodePage page) {
    final blocks = <KumihanBlock>[];

    _appendSection(
      blocks,
      htmlFragment: page.prefaceHtml,
      fallbackText: page.preface,
      baseUrl: page.url,
    );
    _appendSection(
      blocks,
      htmlFragment: page.bodyHtml,
      fallbackText: page.body,
      baseUrl: page.url,
    );
    _appendSection(
      blocks,
      htmlFragment: page.afterwordHtml,
      fallbackText: page.afterword,
      baseUrl: page.url,
    );

    _trimTrailingBlankParagraphs(blocks);

    if (blocks.isEmpty) {
      blocks.add(
        const KumihanParagraphBlock(
          children: <KumihanInline>[KumihanTextInline('本文がありません。')],
        ),
      );
    }

    return KumihanDocument(blocks: blocks, headerTitle: _headerTitle(page));
  }

  void _appendSection(
    List<KumihanBlock> blocks, {
    required String? htmlFragment,
    required String? fallbackText,
    required String baseUrl,
  }) {
    final sectionBlocks = _trimEdgeBlankParagraphs(
      _parseSection(
        htmlFragment: htmlFragment,
        fallbackText: fallbackText,
        baseUrl: baseUrl,
      ),
    );
    if (sectionBlocks.isEmpty) {
      return;
    }

    if (blocks.isNotEmpty) {
      _trimTrailingBlankParagraphs(blocks);
      if (blocks.isNotEmpty) {
        blocks.add(_dividerBlock());
      }
    }

    blocks.addAll(sectionBlocks);
  }

  List<KumihanBlock> _parseSection({
    required String? htmlFragment,
    required String? fallbackText,
    required String baseUrl,
  }) {
    final normalizedHtml = htmlFragment?.trim() ?? '';
    if (normalizedHtml.isNotEmpty) {
      final fragment = html_parser.parseFragment(
        normalizedHtml,
        container: 'div',
      );
      final context = _ParserContext(baseUrl: baseUrl);
      return _normalizeBlocks(context.parseBlockChildren(fragment.nodes));
    }

    final normalizedText = fallbackText?.trim() ?? '';
    if (normalizedText.isEmpty) {
      return const <KumihanBlock>[];
    }

    return _normalizeBlocks(
      normalizedText
          .split('\n')
          .map(
            (line) => KumihanParagraphBlock(
              children: line.isEmpty
                  ? const <KumihanInline>[]
                  : <KumihanInline>[KumihanTextInline(line)],
            ),
          )
          .toList(growable: false),
    );
  }

  List<KumihanBlock> _normalizeBlocks(List<KumihanBlock> blocks) {
    return blocks.map(_normalizeBlock).toList(growable: false);
  }

  KumihanBlock _normalizeBlock(KumihanBlock block) {
    if (block is! KumihanParagraphBlock) {
      return block;
    }

    final children = _normalizeParagraphChildren(block.children);
    if (_isBlankInlineList(children)) {
      return KumihanParagraphBlock(
        children: const <KumihanInline>[],
        keepWithPrevious: block.keepWithPrevious,
        leadingCommands: block.leadingCommands,
      );
    }
    if (_isDividerParagraph(children)) {
      return _dividerBlock();
    }

    return KumihanParagraphBlock(
      children: children,
      keepWithPrevious: block.keepWithPrevious,
      leadingCommands: block.leadingCommands,
    );
  }

  List<KumihanInline> _normalizeParagraphChildren(
    List<KumihanInline> children,
  ) {
    final normalized = <KumihanInline>[];
    for (final child in children) {
      normalized.addAll(_normalizeInline(child));
    }
    return normalized;
  }

  List<KumihanInline> _normalizeInline(KumihanInline inline) {
    switch (inline) {
      case KumihanTextInline():
        return _normalizeTextInline(inline.text);
      case KumihanStyledInline():
        return <KumihanInline>[
          KumihanStyledInline(
            children: _normalizeParagraphChildren(inline.children),
            style: inline.style,
          ),
        ];
      case KumihanLinkInline():
        return <KumihanInline>[
          KumihanLinkInline(
            children: _normalizeParagraphChildren(inline.children),
            target: inline.target,
          ),
        ];
      case KumihanRubyInline():
        return <KumihanInline>[
          KumihanRubyInline(
            children: _normalizeParagraphChildren(inline.children),
            ruby: inline.ruby,
            side: inline.side,
          ),
        ];
      default:
        return <KumihanInline>[inline];
    }
  }

  List<KumihanInline> _normalizeTextInline(String text) {
    final children = <KumihanInline>[];
    final buffer = StringBuffer();
    var index = 0;

    while (index < text.length) {
      final digitRunLength = _digitRunLength(text, index);
      if (digitRunLength == 2) {
        if (buffer.isNotEmpty) {
          children.add(KumihanTextInline(buffer.toString()));
          buffer.clear();
        }
        children.add(
          KumihanStyledInline(
            children: <KumihanInline>[
              KumihanTextInline(
                _toHalfWidthDigits(text.substring(index, index + 2)),
              ),
            ],
            style: '縦中横',
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
      children.add(KumihanTextInline(buffer.toString()));
    }

    return children;
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

  bool _isDividerParagraph(List<KumihanInline> children) {
    final text = _plainText(children).trim();
    if (text.isEmpty) {
      return false;
    }
    final normalized = text
        .replaceAll('＊', '*')
        .replaceAll('＝', '=')
        .replaceAll('＿', '_')
        .replaceAll(RegExp(r'[ー―−－]'), '-');
    return RegExp(r'^([*=\-_])\1{3,}$').hasMatch(normalized);
  }

  bool _isBlankInlineList(List<KumihanInline> children) {
    if (children.isEmpty) {
      return true;
    }
    for (final child in children) {
      switch (child) {
        case KumihanTextInline():
          final text = child.text.replaceAll(RegExp(r'[\s　]+'), '');
          if (text.isNotEmpty) {
            return false;
          }
          break;
        case KumihanStyledInline():
          if (!_isBlankInlineList(child.children)) {
            return false;
          }
          break;
        case KumihanLinkInline():
          if (!_isBlankInlineList(child.children)) {
            return false;
          }
          break;
        case KumihanRubyInline():
          if (!_isBlankInlineList(child.children)) {
            return false;
          }
          break;
        default:
          return false;
      }
    }
    return true;
  }

  String _plainText(List<KumihanInline> children) {
    final buffer = StringBuffer();
    for (final child in children) {
      switch (child) {
        case KumihanTextInline():
          buffer.write(child.text);
          break;
        case KumihanStyledInline():
          buffer.write(_plainText(child.children));
          break;
        case KumihanLinkInline():
          buffer.write(_plainText(child.children));
          break;
        case KumihanRubyInline():
          buffer.write(_plainText(child.children));
          break;
        default:
          return '';
      }
    }
    return buffer.toString();
  }

  KumihanParagraphBlock _dividerBlock() {
    return const KumihanParagraphBlock(
      children: <KumihanInline>[KumihanTextInline('――――')],
    );
  }

  List<KumihanBlock> _trimEdgeBlankParagraphs(List<KumihanBlock> blocks) {
    final trimmed = List<KumihanBlock>.from(blocks);
    while (trimmed.isNotEmpty && _isBlankParagraph(trimmed.first)) {
      trimmed.removeAt(0);
    }
    while (trimmed.isNotEmpty && _isBlankParagraph(trimmed.last)) {
      trimmed.removeLast();
    }
    return trimmed;
  }

  void _trimTrailingBlankParagraphs(List<KumihanBlock> blocks) {
    while (blocks.isNotEmpty && _isBlankParagraph(blocks.last)) {
      blocks.removeLast();
    }
  }

  bool _isBlankParagraph(KumihanBlock block) {
    return block is KumihanParagraphBlock && _isBlankInlineList(block.children);
  }

  String _headerTitle(NarouEpisodePage page) {
    final parts = <String>[
      if ((page.novelTitle ?? '').isNotEmpty) page.novelTitle!,
      if ((page.title ?? '').isNotEmpty) page.title!,
    ];
    if (parts.isEmpty) {
      return '';
    }
    return parts.join(' / ');
  }
}

class _ParserContext {
  const _ParserContext({required this.baseUrl});

  final String baseUrl;

  List<KumihanBlock> parseBlockChildren(Iterable<html.Node> nodes) {
    final blocks = <KumihanBlock>[];
    for (final node in nodes) {
      blocks.addAll(_parseBlock(node));
    }
    return blocks;
  }

  List<KumihanBlock> _parseBlock(html.Node node) {
    if (node is html.Text) {
      return _paragraphsFromLooseText(node.text);
    }
    if (node is! html.Element) {
      return const <KumihanBlock>[];
    }

    final tag = node.localName?.toLowerCase();
    switch (tag) {
      case 'p':
        return <KumihanBlock>[
          KumihanParagraphBlock(children: _parseInlineChildren(node.nodes)),
        ];
      case 'br':
        return const <KumihanBlock>[
          KumihanParagraphBlock(children: <KumihanInline>[]),
        ];
      case 'img':
        return <KumihanBlock>[
          KumihanParagraphBlock(children: _imageInlines(node)),
        ];
      case 'hr':
        return const <KumihanBlock>[
          KumihanParagraphBlock(
            children: <KumihanInline>[KumihanTextInline('――――')],
          ),
        ];
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        return <KumihanBlock>[
          KumihanParagraphBlock(
            children: <KumihanInline>[
              KumihanStyledInline(
                children: _parseInlineChildren(node.nodes),
                style: '中見出し',
              ),
            ],
          ),
        ];
      case 'div':
      case 'section':
      case 'article':
      case 'figure':
      case 'body':
        return parseBlockChildren(node.nodes);
      case 'ul':
      case 'ol':
        return _parseList(node, ordered: tag == 'ol');
      default:
        return <KumihanBlock>[
          KumihanParagraphBlock(children: _parseInlineChildren(node.nodes)),
        ];
    }
  }

  List<KumihanBlock> _parseList(html.Element list, {required bool ordered}) {
    final blocks = <KumihanBlock>[];
    var index = ordered ? int.tryParse(list.attributes['start'] ?? '') ?? 1 : 1;
    for (final child in list.children) {
      if (child.localName?.toLowerCase() != 'li') {
        continue;
      }
      final marker = ordered ? '$index. ' : '・';
      final children = <KumihanInline>[
        KumihanTextInline(marker),
        ..._parseInlineChildren(child.nodes),
      ];
      blocks.add(KumihanParagraphBlock(children: children));
      index += 1;
    }
    return blocks;
  }

  List<KumihanBlock> _paragraphsFromLooseText(String rawText) {
    final normalized = rawText
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'[\t\r]+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return const <KumihanBlock>[];
    }

    return normalized
        .split('\n')
        .map(
          (line) => KumihanParagraphBlock(
            children: <KumihanInline>[KumihanTextInline(line.trim())],
          ),
        )
        .toList(growable: false);
  }

  List<KumihanInline> _parseInlineChildren(Iterable<html.Node> nodes) {
    final children = <KumihanInline>[];
    for (final node in nodes) {
      children.addAll(_parseInline(node));
    }
    return _splitAndTrimParagraphChildren(_mergeAdjacentText(children));
  }

  List<KumihanInline> _parseInline(html.Node node) {
    if (node is html.Text) {
      final text = _normalizeInlineText(node.text);
      if (text.isEmpty) {
        return const <KumihanInline>[];
      }
      return <KumihanInline>[KumihanTextInline(text)];
    }
    if (node is! html.Element) {
      return const <KumihanInline>[];
    }

    final tag = node.localName?.toLowerCase();
    switch (tag) {
      case 'br':
        return const <KumihanInline>[KumihanTextInline('\n')];
      case 'img':
        return _imageInlines(node);
      case 'a':
        final children = _parseInlineChildren(node.nodes);
        if (children.length == 1 && children.first is KumihanImageInline) {
          return children;
        }
        final href = absoluteUrl(node.attributes['href'], baseUrl);
        if (href == null || href.isEmpty) {
          return children;
        }
        return <KumihanInline>[
          KumihanLinkInline(children: children, target: href),
        ];
      case 'ruby':
        return _parseRuby(node);
      case 'strong':
      case 'b':
        return <KumihanInline>[
          KumihanStyledInline(
            children: _parseInlineChildren(node.nodes),
            style: '太字',
          ),
        ];
      case 'em':
      case 'i':
        return <KumihanInline>[
          KumihanStyledInline(
            children: _parseInlineChildren(node.nodes),
            style: '斜体',
          ),
        ];
      case 'div':
      case 'span':
      case 'section':
      case 'article':
        return _parseInlineChildren(node.nodes);
      default:
        return _parseInlineChildren(node.nodes);
    }
  }

  List<KumihanInline> _parseRuby(html.Element node) {
    final ruby = <String>[];
    final baseChildren = <KumihanInline>[];

    for (final child in node.nodes) {
      if (child is html.Element) {
        final tag = child.localName?.toLowerCase();
        if (tag == 'rt') {
          final text = _normalizeInlineText(child.text).trim();
          if (text.isNotEmpty) {
            ruby.add(text);
          }
          continue;
        }
        if (tag == 'rp') {
          continue;
        }
      }
      baseChildren.addAll(_parseInline(child));
    }

    final mergedBase = _splitAndTrimParagraphChildren(
      _mergeAdjacentText(baseChildren),
    );
    final annotation = ruby.join(' ').trim();
    if (mergedBase.isEmpty) {
      return annotation.isEmpty
          ? const <KumihanInline>[]
          : <KumihanInline>[KumihanTextInline(annotation)];
    }
    if (annotation.isEmpty) {
      return mergedBase;
    }
    return <KumihanInline>[
      KumihanRubyInline(children: mergedBase, ruby: annotation),
    ];
  }

  List<KumihanInline> _imageInlines(html.Element node) {
    final src = absoluteUrl(node.attributes['src'], baseUrl);
    if (src == null || src.isEmpty) {
      final alt = _normalizeInlineText(node.attributes['alt'] ?? '');
      return alt.isEmpty
          ? const <KumihanInline>[]
          : <KumihanInline>[KumihanTextInline(alt)];
    }

    return <KumihanInline>[
      KumihanImageInline(
        path: src,
        width: _parseDimension(node.attributes['width']),
        height: _parseDimension(node.attributes['height']),
      ),
    ];
  }

  String _normalizeInlineText(String value) {
    return value
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'[ \t\r\n]+'), ' ');
  }

  List<KumihanInline> _mergeAdjacentText(List<KumihanInline> children) {
    final merged = <KumihanInline>[];
    for (final child in children) {
      if (child is KumihanTextInline &&
          merged.isNotEmpty &&
          merged.last is KumihanTextInline) {
        final previous = merged.removeLast() as KumihanTextInline;
        merged.add(KumihanTextInline(previous.text + child.text));
        continue;
      }
      merged.add(child);
    }
    return merged;
  }

  List<KumihanInline> _splitAndTrimParagraphChildren(
    List<KumihanInline> children,
  ) {
    final trimmed = List<KumihanInline>.from(children);
    if (trimmed.isEmpty) {
      return trimmed;
    }

    if (trimmed.first case final KumihanTextInline first) {
      final text = first.text.replaceFirst(RegExp(r'^[ \t\f]+'), '');
      trimmed[0] = KumihanTextInline(text);
      if (text.isEmpty) {
        trimmed.removeAt(0);
      }
    }

    if (trimmed.isEmpty) {
      return trimmed;
    }

    if (trimmed.last case final KumihanTextInline last) {
      final text = last.text.replaceFirst(RegExp(r'[ \t\f]+$'), '');
      trimmed[trimmed.length - 1] = KumihanTextInline(text);
      if (text.isEmpty) {
        trimmed.removeLast();
      }
    }

    return trimmed;
  }

  double? _parseDimension(String? raw) {
    final normalized = raw?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    final match = RegExp(r'^[0-9]+(?:\.[0-9]+)?').firstMatch(normalized);
    if (match == null) {
      return null;
    }
    return double.tryParse(match.group(0)!);
  }
}

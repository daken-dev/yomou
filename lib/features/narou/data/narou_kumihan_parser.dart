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
      title: '前書き',
      htmlFragment: page.prefaceHtml,
      fallbackText: page.preface,
      baseUrl: page.url,
      showHeading: true,
    );
    _appendSection(
      blocks,
      title: null,
      htmlFragment: page.bodyHtml,
      fallbackText: page.body,
      baseUrl: page.url,
      showHeading: false,
    );
    _appendSection(
      blocks,
      title: 'あとがき',
      htmlFragment: page.afterwordHtml,
      fallbackText: page.afterword,
      baseUrl: page.url,
      showHeading: true,
    );

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
    required String? title,
    required String? htmlFragment,
    required String? fallbackText,
    required String baseUrl,
    required bool showHeading,
  }) {
    final sectionBlocks = _parseSection(
      htmlFragment: htmlFragment,
      fallbackText: fallbackText,
      baseUrl: baseUrl,
    );
    if (sectionBlocks.isEmpty) {
      return;
    }

    if (blocks.isNotEmpty && !_isBlankParagraph(blocks.last)) {
      blocks.add(const KumihanParagraphBlock(children: <KumihanInline>[]));
    }

    if (showHeading && title != null && title.isNotEmpty) {
      blocks.add(
        KumihanParagraphBlock(
          children: <KumihanInline>[
            KumihanStyledInline(
              children: <KumihanInline>[KumihanTextInline(title)],
              style: '中見出し',
            ),
          ],
        ),
      );
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
      return context.parseBlockChildren(fragment.nodes);
    }

    final normalizedText = fallbackText?.trim() ?? '';
    if (normalizedText.isEmpty) {
      return const <KumihanBlock>[];
    }

    return normalizedText
        .split('\n')
        .map(
          (line) => KumihanParagraphBlock(
            children: line.isEmpty
                ? const <KumihanInline>[]
                : <KumihanInline>[KumihanTextInline(line)],
          ),
        )
        .toList(growable: false);
  }

  bool _isBlankParagraph(KumihanBlock block) {
    return block is KumihanParagraphBlock && block.children.isEmpty;
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

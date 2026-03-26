import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';

Future<void> openExternalUrlInBrowser(BuildContext context, String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('リンクURLが不正です。')));
    return;
  }

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (launched || !context.mounted) {
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('外部ブラウザを起動できませんでした。')));
}

Uri? buildWorkPageUri(NovelSite site, String novelId, {String? aozoraCardUrl}) {
  switch (site) {
    case NovelSite.narou:
    case NovelSite.narouR18:
      final normalized = novelId.trim().toLowerCase();
      if (normalized.isEmpty) {
        return null;
      }
      final host = site.workHost;
      if (host == null) {
        return null;
      }
      return Uri.https(host, '/$normalized/');
    case NovelSite.kakuyomu:
      final normalized = novelId.trim();
      if (normalized.isEmpty) {
        return null;
      }
      return Uri.https('kakuyomu.jp', '/works/$normalized');
    case NovelSite.novelup:
      final normalized = novelId.trim();
      if (normalized.isEmpty) {
        return null;
      }
      return Uri.https('novelup.plus', '/story/$normalized');
    case NovelSite.hameln:
      final normalized = novelId.trim();
      if (normalized.isEmpty) {
        return null;
      }
      return Uri.https('syosetu.org', '/novel/$normalized/');
    case NovelSite.aozora:
      final url = aozoraCardUrl?.trim();
      if (url == null || url.isEmpty) {
        return null;
      }
      return Uri.tryParse(url);
  }
}

Future<void> openWorkPageInExternalBrowser(
  BuildContext context,
  NovelSite site,
  String novelId, {
  String? aozoraCardUrl,
}) async {
  final uri = buildWorkPageUri(site, novelId, aozoraCardUrl: aozoraCardUrl);
  if (uri == null) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('作品ページのURLを取得できませんでした。')));
    return;
  }

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (launched || !context.mounted) {
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('外部ブラウザを起動できませんでした。')));
}

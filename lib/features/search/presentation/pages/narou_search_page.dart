import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/hameln/data/hameln_web_client.dart';
import 'package:yomou/features/kakuyomu/domain/entities/kakuyomu_genre.dart';
import 'package:yomou/features/narou/domain/entities/narou_genre.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_target.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novelup/domain/entities/novelup_genre.dart';

class NarouSearchPage extends ConsumerStatefulWidget {
  const NarouSearchPage({super.key, required this.site});

  final NovelSite site;

  @override
  ConsumerState<NarouSearchPage> createState() => _NarouSearchPageState();
}

class _NarouSearchPageState extends ConsumerState<NarouSearchPage> {
  late final TextEditingController _queryController;
  NovelSearchTarget _target = NovelSearchTarget.all;
  int? _genreCode;
  String? _original;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final supportsTarget =
        widget.site != NovelSite.kakuyomu &&
        widget.site != NovelSite.novelup &&
        widget.site != NovelSite.hameln;
    final supportsGenre = widget.site != NovelSite.hameln;
    final supportsOriginal = widget.site == NovelSite.hameln;
    final genreItems = _genreOptions(widget.site);
    final originalOptions = supportsOriginal
        ? ref.watch(hamelnOriginalOptionsProvider)
        : const AsyncData<List<HamelnOriginalOption>>(<HamelnOriginalOption>[]);

    return AppScaffold(
      title: '検索',
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // Search text field with modern styling
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: ListenableBuilder(
                  listenable: _queryController,
                  builder: (context, _) {
                    if (_queryController.text.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () => _queryController.clear(),
                    );
                  },
                ),
                hintText: widget.site == NovelSite.kakuyomu
                    ? '作品名やキーワード'
                    : widget.site == NovelSite.novelup
                    ? '作品名やキーワード'
                    : widget.site == NovelSite.hameln
                    ? '作品名や本文キーワード'
                    : '作品名、あらすじ、キーワードなど',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
            ),

            const SizedBox(height: 24),

            if (supportsTarget) ...[
              _SectionLabel(label: '検索範囲', colorScheme: colorScheme),
              const SizedBox(height: 8),
              DropdownButtonFormField<NovelSearchTarget>(
                initialValue: _target,
                decoration: _inputDecoration(colorScheme),
                items: [
                  for (final value in NovelSearchTargetX.selectableValues)
                    DropdownMenuItem<NovelSearchTarget>(
                      value: value,
                      child: Text(value.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _target = value);
                  }
                },
              ),
              const SizedBox(height: 24),
            ],

            if (supportsGenre) ...[
              _SectionLabel(label: 'ジャンル', colorScheme: colorScheme),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: _genreCode,
                decoration: _inputDecoration(colorScheme),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('指定なし'),
                  ),
                  for (final genre in genreItems)
                    DropdownMenuItem<int?>(
                      value: genre.code,
                      child: Text(genre.label),
                    ),
                ],
                onChanged: (value) => setState(() => _genreCode = value),
              ),
              const SizedBox(height: 32),
            ],

            if (supportsOriginal) ...[
              _SectionLabel(label: '原作', colorScheme: colorScheme),
              const SizedBox(height: 8),
              originalOptions.when(
                data: (items) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _original,
                    decoration: _inputDecoration(colorScheme),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('指定なし'),
                      ),
                      for (final item in items)
                        DropdownMenuItem<String?>(
                          value: item.value,
                          child: Text(item.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => _original = value),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text(
                  '原作一覧の取得に失敗しました: $error',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Search button
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.search_rounded),
              label: const Text('検索する'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();

    final request = NovelSearchRequest(
      site: widget.site,
      query: _queryController.text,
      target: _target,
      genreCode: _genreCode,
      original: _original,
      order: NovelSearchOrder.newest,
    );

    if (!request.hasQuery &&
        request.genreCode == null &&
        request.original == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.site == NovelSite.hameln
                ? 'テキストか原作を指定してください。'
                : widget.site == NovelSite.kakuyomu ||
                      widget.site == NovelSite.novelup
                ? 'テキストを指定してください。'
                : 'テキストかジャンルを指定してください。',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final location = Uri(
      path: '${widget.site.routePrefix}/search/results',
      queryParameters: request.toQueryParameters(),
    ).toString();
    context.push(location);
  }
}

InputDecoration _inputDecoration(ColorScheme colorScheme) {
  return InputDecoration(
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

List<({int code, String label})> _genreOptions(NovelSite site) {
    return switch (site) {
      NovelSite.kakuyomu => [
      for (final genre in KakuyomuGenre.values)
        (code: genre.code, label: genre.label),
    ],
    NovelSite.novelup => [
      for (final genre in NovelupGenre.values)
        (code: genre.code, label: genre.label),
    ],
    _ => [
      for (final genre in NarouGenre.values)
        (code: genre.code, label: genre.label),
    ],
  };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.colorScheme});

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

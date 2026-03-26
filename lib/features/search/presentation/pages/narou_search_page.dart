import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/narou/domain/entities/narou_genre.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_target.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';

class NarouSearchPage extends StatefulWidget {
  const NarouSearchPage({super.key});

  @override
  State<NarouSearchPage> createState() => _NarouSearchPageState();
}

class _NarouSearchPageState extends State<NarouSearchPage> {
  late final TextEditingController _queryController;
  NovelSearchTarget _target = NovelSearchTarget.all;
  int? _genreCode;

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
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                hintText: '作品名、あらすじ、キーワードなど',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
            ),

            const SizedBox(height: 24),

            // Search target section
            _SectionLabel(label: '検索範囲', colorScheme: colorScheme),
            const SizedBox(height: 8),
            DropdownButtonFormField<NovelSearchTarget>(
              initialValue: _target,
              decoration: InputDecoration(
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
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

            // Genre section
            _SectionLabel(label: 'ジャンル', colorScheme: colorScheme),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: _genreCode,
              decoration: InputDecoration(
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('指定なし')),
                for (final genre in NarouGenre.values)
                  DropdownMenuItem<int?>(
                    value: genre.code,
                    child: Text(genre.label),
                  ),
              ],
              onChanged: (value) => setState(() => _genreCode = value),
            ),

            const SizedBox(height: 32),

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
      site: NovelSite.narou,
      query: _queryController.text,
      target: _target,
      genreCode: _genreCode,
      order: NovelSearchOrder.newest,
    );

    if (!request.hasQuery && request.genreCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('テキストかジャンルを指定してください。'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final location = Uri(
      path: '/narou/search/results',
      queryParameters: request.toQueryParameters(),
    ).toString();
    context.push(location);
  }
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

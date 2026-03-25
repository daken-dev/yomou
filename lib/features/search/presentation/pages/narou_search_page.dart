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
    return AppScaffold(
      title: '検索',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _queryController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'テキスト',
              hintText: '作品名、あらすじ、キーワードなど',
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<NovelSearchTarget>(
            initialValue: _target,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '検索範囲',
            ),
            items: [
              for (final value in NovelSearchTargetX.selectableValues)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _target = value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: _genreCode,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'ジャンル',
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
          const SizedBox(height: 24),
          FilledButton(onPressed: _submit, child: const Text('検索')),
        ],
      ),
    );
  }

  void _submit() {
    final request = NovelSearchRequest(
      site: NovelSite.narou,
      query: _queryController.text,
      target: _target,
      genreCode: _genreCode,
      order: NovelSearchOrder.newest,
    );

    if (!request.hasQuery && request.genreCode == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('テキストかジャンルを指定してください。')));
      return;
    }

    final location = Uri(
      path: '/narou/search/results',
      queryParameters: request.toQueryParameters(),
    ).toString();
    context.push(location);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/settings/application/settings_providers.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

class ReaderSettingsPage extends ConsumerWidget {
  const ReaderSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return AppScaffold(
      title: 'リーダー設定',
      body: settingsAsync.when(
        data: (settings) => _ReaderSettingsContent(settings: settings),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ReaderSettingsContent extends ConsumerWidget {
  const _ReaderSettingsContent({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.read(settingsStoreProvider);
    final reader = settings.reader;
    final theme = Theme.of(context);

    Future<void> save(ReaderSettings next) async {
      await store.saveSettings(settings.copyWith(reader: next));
    }

    return ListView(
      children: [
        _SectionHeader(title: '文字'),
        _SegmentedTile<ReaderTapPattern>(
          label: 'タップ領域',
          segments: ReaderTapPattern.values,
          selected: reader.tapPattern,
          segmentLabel: (v) => v.label,
          onChanged: (v) => save(reader.copyWith(tapPattern: v)),
        ),
        const SizedBox(height: 8),
        _SliderTile(
          label: '文字サイズ',
          value: reader.fontSize.clamp(10, 32).toDouble(),
          displayValue: reader.fontSize.toStringAsFixed(0),
          min: 10,
          max: 32,
          divisions: 18,
          onChanged: (value) => save(reader.copyWith(fontSize: value)),
          onReset: reader.fontSize == const ReaderSettings.defaults().fontSize
              ? null
              : () => save(
                  reader.copyWith(
                    fontSize: const ReaderSettings.defaults().fontSize,
                  ),
                ),
        ),

        const SizedBox(height: 8),
        _SectionHeader(title: '余白'),
        _ActionTile(
          label: '上部 UI 余白',
          value: _formatInsets(
            top: reader.topUiPaddingTop,
            right: reader.topUiPaddingRight,
            bottom: reader.topUiPaddingBottom,
            left: reader.topUiPaddingLeft,
          ),
          onTap: () => _editInsets(
            context,
            title: '上部 UI 余白',
            initial: _InsetsDraft(
              top: reader.topUiPaddingTop,
              right: reader.topUiPaddingRight,
              bottom: reader.topUiPaddingBottom,
              left: reader.topUiPaddingLeft,
            ),
            defaults: const _InsetsDraft(top: 0, right: 0, bottom: 0, left: 0),
            onSaved: (draft) => save(
              reader.copyWith(
                topUiPaddingTop: draft.top,
                topUiPaddingRight: draft.right,
                topUiPaddingBottom: draft.bottom,
                topUiPaddingLeft: draft.left,
              ),
            ),
          ),
        ),
        _ActionTile(
          label: '本文余白',
          value:
              '上 ${reader.bodyPaddingTop.round()} / 内 ${reader.bodyPaddingInner.round()} / 外 ${reader.bodyPaddingOuter.round()} / 下 ${reader.bodyPaddingBottom.round()}',
          onTap: () => _editBodyPadding(
            context,
            initial: _BodyPaddingDraft(
              top: reader.bodyPaddingTop,
              inner: reader.bodyPaddingInner,
              outer: reader.bodyPaddingOuter,
              bottom: reader.bodyPaddingBottom,
            ),
            defaults: const _BodyPaddingDraft(
              top: 16,
              inner: 16,
              outer: 16,
              bottom: 16,
            ),
            onSaved: (draft) => save(
              reader.copyWith(
                bodyPaddingTop: draft.top,
                bodyPaddingInner: draft.inner,
                bodyPaddingOuter: draft.outer,
                bodyPaddingBottom: draft.bottom,
              ),
            ),
          ),
        ),
        _ActionTile(
          label: '下部 UI 余白',
          value: _formatInsets(
            top: reader.bottomUiPaddingTop,
            right: reader.bottomUiPaddingRight,
            bottom: reader.bottomUiPaddingBottom,
            left: reader.bottomUiPaddingLeft,
          ),
          onTap: () => _editInsets(
            context,
            title: '下部 UI 余白',
            initial: _InsetsDraft(
              top: reader.bottomUiPaddingTop,
              right: reader.bottomUiPaddingRight,
              bottom: reader.bottomUiPaddingBottom,
              left: reader.bottomUiPaddingLeft,
            ),
            defaults: const _InsetsDraft(top: 0, right: 0, bottom: 0, left: 0),
            onSaved: (draft) => save(
              reader.copyWith(
                bottomUiPaddingTop: draft.top,
                bottomUiPaddingRight: draft.right,
                bottomUiPaddingBottom: draft.bottom,
                bottomUiPaddingLeft: draft.left,
              ),
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('インカメラ回避'),
          subtitle: const Text('上部 UI の余白にノッチ分を加算する'),
          value: reader.avoidNotch,
          onChanged: (value) => save(reader.copyWith(avoidNotch: value)),
        ),

        const SizedBox(height: 8),
        _SectionHeader(title: '紙面'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SegmentedButton<ReaderPaperColorPreset>(
            segments: ReaderPaperColorPreset.values
                .map(
                  (preset) => ButtonSegment<ReaderPaperColorPreset>(
                    value: preset,
                    label: Text(preset.label),
                  ),
                )
                .toList(growable: false),
            selected: {reader.paperColorPreset},
            onSelectionChanged: (value) {
              save(reader.copyWith(paperColorPreset: value.first));
            },
          ),
        ),
        SwitchListTile(
          title: const Text('紙のテクスチャ'),
          subtitle: const Text('紙の質感を再現する'),
          value: reader.usePaperTexture,
          onChanged: (value) => save(reader.copyWith(usePaperTexture: value)),
        ),
        SwitchListTile(
          title: const Text('リーダー中央影の無効'),
          subtitle: const Text('見開き中央の影を表示しない'),
          value: reader.disableCenterShadow,
          onChanged: (value) =>
              save(reader.copyWith(disableCenterShadow: value)),
        ),

        const SizedBox(height: 8),
        _SectionHeader(title: '表示'),
        SwitchListTile(
          title: const Text('横画面で見開き'),
          subtitle: const Text('横向き時に2ページ並べて表示'),
          value: reader.enableLandscapeDoublePage,
          onChanged: (value) =>
              save(reader.copyWith(enableLandscapeDoublePage: value)),
        ),
        SwitchListTile(
          title: const Text('ページめくりアニメーション'),
          subtitle: const Text('無効時はタップ/スワイプで即時にページ移動する'),
          value: reader.pageTurnAnimationEnabled,
          onChanged: (value) =>
              save(reader.copyWith(pageTurnAnimationEnabled: value)),
        ),
        _SegmentedTile<ReaderSinglePagePosition>(
          label: '単ページ表示位置',
          segments: ReaderSinglePagePosition.values,
          selected: reader.singlePagePosition,
          segmentLabel: (v) => v.label,
          onChanged: (v) => save(reader.copyWith(singlePagePosition: v)),
        ),
        SwitchListTile(
          title: const Text('前書きを表示'),
          value: reader.showPreface,
          onChanged: (value) => save(reader.copyWith(showPreface: value)),
        ),
        SwitchListTile(
          title: const Text('あとがきを表示'),
          value: reader.showAfterword,
          onChanged: (value) => save(reader.copyWith(showAfterword: value)),
        ),

        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.tonalIcon(
            onPressed: () => _confirmReset(context, store),
            icon: const Icon(Icons.settings_backup_restore),
            label: const Text('リーダー設定を規定値に戻す'),
            style: FilledButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _editInsets(
    BuildContext context, {
    required String title,
    required _InsetsDraft initial,
    required _InsetsDraft defaults,
    required Future<void> Function(_InsetsDraft draft) onSaved,
  }) async {
    final draft = await showModalBottomSheet<_InsetsDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _InsetsEditorSheet(
        title: title,
        initial: initial,
        defaults: defaults,
      ),
    );
    if (draft != null) {
      await onSaved(draft);
    }
  }

  Future<void> _editBodyPadding(
    BuildContext context, {
    required _BodyPaddingDraft initial,
    required _BodyPaddingDraft defaults,
    required Future<void> Function(_BodyPaddingDraft draft) onSaved,
  }) async {
    final draft = await showModalBottomSheet<_BodyPaddingDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _BodyPaddingEditorSheet(initial: initial, defaults: defaults),
    );
    if (draft != null) {
      await onSaved(draft);
    }
  }

  Future<void> _confirmReset(BuildContext context, dynamic store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リーダー設定を規定値に戻す'),
        content: const Text('リーダーの設定が初期状態にリセットされます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('リセット'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await store.saveSettings(
        settings.copyWith(reader: const ReaderSettings.defaults()),
      );
    }
  }

  String _formatInsets({
    required double top,
    required double right,
    required double bottom,
    required double left,
  }) {
    return '上 ${top.round()} / 右 ${right.round()} / 下 ${bottom.round()} / 左 ${left.round()}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _SegmentedTile<T extends Enum> extends StatelessWidget {
  const _SegmentedTile({
    super.key,
    required this.label,
    required this.segments,
    required this.selected,
    required this.segmentLabel,
    required this.onChanged,
  });

  final String label;
  final List<T> segments;
  final T selected;
  final String Function(T) segmentLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SegmentedButton<T>(
          segments: segments
              .map(
                (v) => ButtonSegment<T>(value: v, label: Text(segmentLabel(v))),
              )
              .toList(growable: false),
          selected: {selected},
          onSelectionChanged: (value) => onChanged(value.first),
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.onReset,
  });

  final String label;
  final double value;
  final String displayValue;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(
            displayValue,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onReset != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                icon: const Icon(Icons.restart_alt, size: 20),
                tooltip: '規定値に戻す',
                visualDensity: VisualDensity.compact,
                onPressed: onReset,
              ),
            ),
        ],
      ),
      subtitle: Slider(
        min: min,
        max: max,
        divisions: divisions,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.tune),
      onTap: onTap,
    );
  }
}

class _InsetsEditorSheet extends StatefulWidget {
  const _InsetsEditorSheet({
    required this.title,
    required this.initial,
    required this.defaults,
  });

  final String title;
  final _InsetsDraft initial;
  final _InsetsDraft defaults;

  @override
  State<_InsetsEditorSheet> createState() => _InsetsEditorSheetState();
}

class _InsetsEditorSheetState extends State<_InsetsEditorSheet> {
  late _InsetsDraft _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(widget.title),
              subtitle: Text(
                '上 ${_draft.top.round()} / 右 ${_draft.right.round()} / 下 ${_draft.bottom.round()} / 左 ${_draft.left.round()}',
              ),
              trailing: TextButton(
                onPressed: () => setState(() {
                  _draft = widget.defaults;
                }),
                child: const Text('リセット'),
              ),
            ),
            _DraftSlider(
              label: '上',
              value: _draft.top,
              onChanged: (value) => setState(() {
                _draft = _draft.copyWith(top: value);
              }),
            ),
            _DraftSlider(
              label: '右',
              value: _draft.right,
              onChanged: (value) => setState(() {
                _draft = _draft.copyWith(right: value);
              }),
            ),
            _DraftSlider(
              label: '下',
              value: _draft.bottom,
              onChanged: (value) => setState(() {
                _draft = _draft.copyWith(bottom: value);
              }),
            ),
            _DraftSlider(
              label: '左',
              value: _draft.left,
              onChanged: (value) => setState(() {
                _draft = _draft.copyWith(left: value);
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_draft),
                      child: const Text('適用'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyPaddingEditorSheet extends StatefulWidget {
  const _BodyPaddingEditorSheet({
    required this.initial,
    required this.defaults,
  });

  final _BodyPaddingDraft initial;
  final _BodyPaddingDraft defaults;

  @override
  State<_BodyPaddingEditorSheet> createState() =>
      _BodyPaddingEditorSheetState();
}

class _BodyPaddingEditorSheetState extends State<_BodyPaddingEditorSheet> {
  late _BodyPaddingDraft _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('本文余白'),
              subtitle: Text(
                '上 ${_draft.top.round()} / 内 ${_draft.inner.round()} / 外 ${_draft.outer.round()} / 下 ${_draft.bottom.round()}',
              ),
              trailing: TextButton(
                onPressed: () => setState(() {
                  _draft = widget.defaults;
                }),
                child: const Text('リセット'),
              ),
            ),
            _DraftSlider(
              label: '上',
              value: _draft.top,
              onChanged: (value) => setState(() {
                _draft = _draft.copyWith(top: value);
              }),
            ),
            _DraftSlider(
              label: '内',
              value: _draft.inner,
              onChanged: (value) => setState(() {
                _draft = _draft.copyWith(inner: value);
              }),
            ),
            _DraftSlider(
              label: '外',
              value: _draft.outer,
              onChanged: (value) => setState(() {
                _draft = _draft.copyWith(outer: value);
              }),
            ),
            _DraftSlider(
              label: '下',
              value: _draft.bottom,
              onChanged: (value) => setState(() {
                _draft = _draft.copyWith(bottom: value);
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_draft),
                      child: const Text('適用'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftSlider extends StatelessWidget {
  const _DraftSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 60).toDouble();
    return ListTile(
      title: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(
            '${clamped.round()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      subtitle: Slider(
        min: 0,
        max: 60,
        divisions: 12,
        value: clamped,
        onChanged: onChanged,
      ),
    );
  }
}

class _InsetsDraft {
  const _InsetsDraft({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  final double top;
  final double right;
  final double bottom;
  final double left;

  _InsetsDraft copyWith({
    double? top,
    double? right,
    double? bottom,
    double? left,
  }) {
    return _InsetsDraft(
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
    );
  }
}

class _BodyPaddingDraft {
  const _BodyPaddingDraft({
    required this.top,
    required this.inner,
    required this.outer,
    required this.bottom,
  });

  final double top;
  final double inner;
  final double outer;
  final double bottom;

  _BodyPaddingDraft copyWith({
    double? top,
    double? inner,
    double? outer,
    double? bottom,
  }) {
    return _BodyPaddingDraft(
      top: top ?? this.top,
      inner: inner ?? this.inner,
      outer: outer ?? this.outer,
      bottom: bottom ?? this.bottom,
    );
  }
}

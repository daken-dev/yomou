import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/settings/data/settings_store.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

final settingsStoreProvider = Provider<SettingsStore>((ref) {
  final store = SettingsStore(ref.watch(appDatabaseProvider));
  ref.onDispose(() {
    store.dispose();
  });
  return store;
});

final appSettingsProvider = StreamProvider<AppSettings>((ref) async* {
  final store = ref.watch(settingsStoreProvider);

  yield await store.readSettings();
  await for (final _ in store.changes) {
    yield await store.readSettings();
  }
});

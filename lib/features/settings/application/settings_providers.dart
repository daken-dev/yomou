import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/settings/data/settings_store.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

final settingsStoreProvider = Provider<SettingsStore>((ref) {
  return SettingsStore(ref.watch(appDatabaseProvider));
});

final settingsChangeTickProvider = StreamProvider<int>((ref) async* {
  var tick = 0;
  yield tick;

  await for (final _ in ref.watch(settingsStoreProvider).changes) {
    tick += 1;
    yield tick;
  }
});

final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  ref.watch(settingsChangeTickProvider);
  return ref.watch(settingsStoreProvider).readSettings();
});

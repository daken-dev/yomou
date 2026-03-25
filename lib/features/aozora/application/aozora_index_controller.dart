import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/aozora/data/aozora_index_client.dart';
import 'package:yomou/features/aozora/data/aozora_index_store.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';

final aozoraIndexControllerProvider =
    AsyncNotifierProvider<AozoraIndexController, AozoraIndexControllerState>(
      AozoraIndexController.new,
    );

class AozoraIndexController extends AsyncNotifier<AozoraIndexControllerState> {
  @override
  Future<AozoraIndexControllerState> build() async {
    final status = await ref.watch(aozoraIndexStoreProvider).getStatus();
    return AozoraIndexControllerState(status: status, isUpdating: false);
  }

  Future<void> downloadOrUpdate() async {
    final current = state.value;
    if (current == null || current.isUpdating) {
      return;
    }

    state = AsyncData(current.copyWith(isUpdating: true));

    try {
      final works = await ref.watch(aozoraIndexClientProvider).fetchIndex();
      await ref.watch(aozoraIndexStoreProvider).replaceAll(
        works: works,
        fetchedAt: DateTime.now(),
        sourceUrl: aozoraIndexZipUrl,
      );
      final status = await ref.watch(aozoraIndexStoreProvider).getStatus();
      state = AsyncData(
        AozoraIndexControllerState(status: status, isUpdating: false),
      );
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
      rethrow;
    }
  }
}

class AozoraIndexControllerState {
  const AozoraIndexControllerState({
    required this.status,
    required this.isUpdating,
  });

  final AozoraIndexStatus status;
  final bool isUpdating;

  AozoraIndexControllerState copyWith({
    AozoraIndexStatus? status,
    bool? isUpdating,
  }) {
    return AozoraIndexControllerState(
      status: status ?? this.status,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

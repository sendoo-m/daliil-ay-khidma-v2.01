import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../directory/data/business.dart';
import '../data/favorites_repository.dart';

final class FavoritesState {
  const FavoritesState({
    this.businesses = const [],
    this.pendingBusinessIds = const {},
  });

  final List<Business> businesses;
  final Set<int> pendingBusinessIds;

  bool containsBusiness(int businessId) =>
      businesses.any((item) => item.id == businessId);

  bool isBusinessPending(int businessId) =>
      pendingBusinessIds.contains(businessId);

  FavoritesState copyWith({
    List<Business>? businesses,
    Set<int>? pendingBusinessIds,
  }) =>
      FavoritesState(
        businesses: businesses ?? this.businesses,
        pendingBusinessIds: pendingBusinessIds ?? this.pendingBusinessIds,
      );
}

final class FavoritesController
    extends StateNotifier<AsyncValue<FavoritesState>> {
  FavoritesController(this._repository)
      : super(const AsyncValue.loading()) {
    refresh();
  }

  final FavoritesRepository _repository;

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    if (previous == null) state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () async => FavoritesState(
        businesses: await _repository.businesses(),
        pendingBusinessIds: previous?.pendingBusinessIds ?? const {},
      ),
    );
  }

  Future<bool> toggleBusiness(Business business) async {
    final current = state.valueOrNull ?? const FavoritesState();
    if (current.isBusinessPending(business.id)) {
      return current.containsBusiness(business.id);
    }

    final wasFavorite = current.containsBusiness(business.id) || business.isFavorite;
    final optimisticBusinesses = wasFavorite
        ? current.businesses
            .where((item) => item.id != business.id)
            .toList(growable: false)
        : <Business>[business, ...current.businesses];
    final pending = {...current.pendingBusinessIds, business.id};

    state = AsyncValue.data(
      current.copyWith(
        businesses: optimisticBusinesses,
        pendingBusinessIds: pending,
      ),
    );

    try {
      final isFavorite = await _repository.toggleBusiness(business.id);
      final latest = state.valueOrNull ?? current;
      final reconciled = isFavorite
          ? <Business>[
              business,
              ...latest.businesses.where((item) => item.id != business.id),
            ]
          : latest.businesses
              .where((item) => item.id != business.id)
              .toList(growable: false);
      state = AsyncValue.data(
        latest.copyWith(
          businesses: reconciled,
          pendingBusinessIds: {...latest.pendingBusinessIds}..remove(business.id),
        ),
      );
      return isFavorite;
    } catch (error, stackTrace) {
      state = AsyncValue.data(current);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

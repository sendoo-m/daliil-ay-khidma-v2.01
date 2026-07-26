import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../catalog/data/catalog_models.dart';

class FavoriteDealButton extends ConsumerWidget {
  const FavoriteDealButton({
    required this.deal,
    this.size = 24,
    super.key,
  });

  final DealSummary deal;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoritesProvider).valueOrNull;
    final isFav = state?.containsDeal(deal.id) ?? false;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: child,
      ),
      child: IconButton(
        key: ValueKey(isFav),
        icon: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: size,
          color: isFav ? Colors.redAccent : null,
        ),
        tooltip: isFav ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
        onPressed: () =>
            ref.read(favoritesProvider.notifier).toggleDeal(deal),
      ),
    );
  }
}

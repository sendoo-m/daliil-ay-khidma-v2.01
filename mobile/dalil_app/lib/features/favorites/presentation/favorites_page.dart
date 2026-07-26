import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/providers.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/presentation/deal_detail_page.dart';
import '../../catalog/presentation/product_detail_page_v2.dart';
import '../../directory/presentation/business_card.dart';
import '../../directory/presentation/business_detail_page.dart';
import '../presentation/favorites_controller.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({this.embedded = false, super.key});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final tabs = [
      Tab(
        icon: const Icon(Icons.store_rounded, size: 20),
        text: isArabic ? 'نشاطات' : 'Businesses',
      ),
      Tab(
        icon: const Icon(Icons.shopping_bag_outlined, size: 20),
        text: isArabic ? 'منتجات' : 'Products',
      ),
      Tab(
        icon: const Icon(Icons.local_offer_outlined, size: 20),
        text: isArabic ? 'عروض' : 'Deals',
      ),
    ];

    final tabContent = DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              tabs: tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _BusinessesTab(),
                _ProductsTab(),
                _DealsTab(),
              ],
            ),
          ),
        ],
      ),
    );

    if (embedded) return tabContent;
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        title: Text(isArabic ? 'المفضلة' : 'Favorites'),
        centerTitle: false,
      ),
      body: SafeArea(child: tabContent),
    );
  }
}

// ─────────────────────────── Businesses Tab ────────────────────────────

class _BusinessesTab extends ConsumerWidget {
  const _BusinessesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return favorites.when(
      loading: () => const _TabLoading(),
      error: (_, __) => _TabError(
        isArabic: isArabic,
        onRetry: () => ref.read(favoritesProvider.notifier).refresh(),
      ),
      data: (state) {
        if (state.businesses.isEmpty) {
          return _TabEmpty(
            icon: Icons.store_outlined,
            title: isArabic ? 'لا توجد نشاطات مفضلة' : 'No favorite businesses',
            subtitle: isArabic
                ? 'اضغط على قلب أي نشاط لحفظه هنا'
                : 'Tap the heart on any business to save it here',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(favoritesProvider.notifier).refresh(),
          child: ListView.separated(
            key: const PageStorageKey('fav-businesses'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: state.businesses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => RepaintBoundary(
              child: BusinessCard(business: state.businesses[index]),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────── Products Tab ────────────────────────────

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return favorites.when(
      loading: () => const _TabLoading(),
      error: (_, __) => _TabError(
        isArabic: isArabic,
        onRetry: () => ref.read(favoritesProvider.notifier).refresh(),
      ),
      data: (state) {
        if (state.products.isEmpty) {
          return _TabEmpty(
            icon: Icons.shopping_bag_outlined,
            title: isArabic ? 'لا توجد منتجات مفضلة' : 'No favorite products',
            subtitle: isArabic
                ? 'اضغط على قلب أي منتج لحفظه هنا'
                : 'Tap the heart on any product to save it here',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(favoritesProvider.notifier).refresh(),
          child: ListView.separated(
            key: const PageStorageKey('fav-products'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: state.products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = state.products[index];
              return RepaintBoundary(
                child: _FavProductCard(
                  product: product,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ProductDetailPageV2(slug: product.slug),
                    ),
                  ),
                  onRemove: () => ref
                      .read(favoritesProvider.notifier)
                      .toggleProduct(product),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────── Deals Tab ────────────────────────────

class _DealsTab extends ConsumerWidget {
  const _DealsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return favorites.when(
      loading: () => const _TabLoading(),
      error: (_, __) => _TabError(
        isArabic: isArabic,
        onRetry: () => ref.read(favoritesProvider.notifier).refresh(),
      ),
      data: (state) {
        if (state.deals.isEmpty) {
          return _TabEmpty(
            icon: Icons.local_offer_outlined,
            title: isArabic ? 'لا توجد عروض مفضلة' : 'No favorite deals',
            subtitle: isArabic
                ? 'اضغط على قلب أي عرض لحفظه هنا'
                : 'Tap the heart on any deal to save it here',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(favoritesProvider.notifier).refresh(),
          child: ListView.separated(
            key: const PageStorageKey('fav-deals'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: state.deals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final deal = state.deals[index];
              return RepaintBoundary(
                child: _FavDealCard(
                  deal: deal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => DealDetailPage(slug: deal.slug),
                    ),
                  ),
                  onRemove: () =>
                      ref.read(favoritesProvider.notifier).toggleDeal(deal),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────── Shared Card Widgets ────────────────────────────

class _FavProductCard extends StatelessWidget {
  const _FavProductCard({
    required this.product,
    required this.onTap,
    required this.onRemove,
  });

  final ProductSummary product;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: product.image != null
                  ? Image.network(
                      product.image!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ImagePlaceholder(
                        icon: Icons.shopping_bag_outlined,
                      ),
                    )
                  : _ImagePlaceholder(icon: Icons.shopping_bag_outlined),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.businessName,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${product.price} ج.م',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      if (product.oldPrice != null) ...
                        [
                          const SizedBox(width: 6),
                          Text(
                            '${product.oldPrice} ج.م',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                    ],
                  ),
                ],
              ),
            ),
            // Remove button
            IconButton(
              icon: const Icon(Icons.favorite_rounded),
              color: AppColors.primary,
              tooltip: 'إزالة من المفضلة',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavDealCard extends StatelessWidget {
  const _FavDealCard({
    required this.deal,
    required this.onTap,
    required this.onRemove,
  });

  final DealSummary deal;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isExpiring = deal.daysRemaining <= 3 && deal.daysRemaining >= 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: deal.image != null
                  ? Image.network(
                      deal.image!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _ImagePlaceholder(icon: Icons.local_offer_outlined),
                    )
                  : _ImagePlaceholder(icon: Icons.local_offer_outlined),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deal.businessName,
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          deal.typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (isExpiring) ...
                        [
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              deal.daysRemaining == 0
                                  ? 'آخر يوم'
                                  : 'ينتهي خلال ${deal.daysRemaining} أيام',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                    ],
                  ),
                ],
              ),
            ),
            // Remove button
            IconButton(
              icon: const Icon(Icons.favorite_rounded),
              color: AppColors.primary,
              tooltip: 'إزالة من المفضلة',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Shared UI Helpers ────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 64,
        height: 64,
        color: AppColors.surfaceMuted,
        child: Icon(icon, size: 28, color: AppColors.muted),
      );
}

class _TabLoading extends StatelessWidget {
  const _TabLoading();

  @override
  Widget build(BuildContext context) => ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(child: LinearProgressIndicator()),
        ),
      );
}

class _TabEmpty extends StatelessWidget {
  const _TabEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 72),
            Icon(icon, size: 72, color: AppColors.primary),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      );
}

class _TabError extends StatelessWidget {
  const _TabError({required this.isArabic, required this.onRetry});

  final bool isArabic;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 52),
              const SizedBox(height: 12),
              Text(
                isArabic ? 'تعذر تحميل المفضلة' : 'Could not load favorites',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(isArabic ? 'إعادة المحاولة' : 'Try again'),
              ),
            ],
          ),
        ),
      );
}

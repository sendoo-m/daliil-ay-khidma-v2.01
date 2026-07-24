import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/providers.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/presentation/catalog_detail_pages.dart';
import '../../auth/presentation/login_page.dart';
import '../../directory/data/business.dart';
import '../../directory/presentation/business_card.dart';
import '../../directory/presentation/search_page.dart';
import '../../location/presentation/nearby_page.dart';
import '../../notifications/presentation/notifications_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({required this.onSearchTap, super.key});

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    final isAuthenticated =
        ref.watch(authControllerProvider).valueOrNull ?? false;
    return Scaffold(
      body: SafeArea(
        child: home.when(
          loading: () => const _HomeLoading(),
          error: (_, __) => _HomeError(
            onRetry: () => ref.invalidate(homeProvider),
          ),
          data: (data) => RefreshIndicator(
            onRefresh: () => ref.refresh(homeProvider.future),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeHeader(
                    onSearchTap: onSearchTap,
                    isAuthenticated: isAuthenticated,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CategoriesSection(categories: data.categories),
                ),
                SliverToBoxAdapter(
                  child: _BusinessesSection(items: data.businesses),
                ),
                SliverToBoxAdapter(
                  child: _ProductsSection(items: data.products),
                ),
                SliverToBoxAdapter(
                  child: _DealsSection(items: data.deals),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onSearchTap,
    required this.isAuthenticated,
  });
  final VoidCallback onSearchTap;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.place_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'دليل أي خدمة',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                        ),
                      ),
                      Text(
                        'كل ما تحتاجه بالقرب منك',
                        style: TextStyle(color: Color(0xFFD9F3E9)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'الإشعارات',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => isAuthenticated
                          ? const NotificationsPage()
                          : const LoginPage(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'تبحث عن إيه النهارده؟',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ابحث عن محل، منتج أو خدمة',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const NearbyPage()),
              ),
              icon: const Icon(Icons.near_me_outlined, size: 20),
              label: const Text('استكشف الأماكن القريبة منك'),
            ),
          ],
        ),
      );
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({required this.categories});
  final List<Map<String, dynamic>> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'الأقسام',
      child: SizedBox(
        height: 112,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final item = categories[index];
            final name = '${item['name_ar'] ?? ''}';
            final iconUrl = '${item['icon'] ?? ''}';
            final categoryId = item['id'] as int?;
            return SizedBox(
              width: 82,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SearchPage(
                      initialQuery: name,
                      initialCategoryId: categoryId,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F5EF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: !iconUrl.startsWith('http')
                          ? const Icon(
                              Icons.grid_view_rounded,
                              color: AppColors.primary,
                            )
                          : Padding(
                              padding: const EdgeInsets.all(14),
                              child: Image.network(
                                iconUrl,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.grid_view_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BusinessesSection extends StatelessWidget {
  const _BusinessesSection({required this.items});
  final List<Business> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'أنشطة مميزة',
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => BusinessCard(business: items[index]),
      ),
    );
  }
}

class _ProductsSection extends StatelessWidget {
  const _ProductsSection({required this.items});
  final List<ProductSummary> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'منتجات وخدمات مختارة',
      child: SizedBox(
        height: 222,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return _ProductCard(item: item);
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item});
  final ProductSummary item;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 166,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProductDetailPage(slug: item.slug),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 128,
                  child: item.image == null || item.image!.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFE7F5EF),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 38,
                            color: AppColors.primary,
                          ),
                        )
                      : Image.network(
                          item.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.shopping_bag_outlined,
                            size: 38,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${item.price} جنيه',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _DealsSection extends StatelessWidget {
  const _DealsSection({required this.items});
  final List<DealSummary> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'عروض لا تفوّتها',
      child: SizedBox(
        height: 166,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return SizedBox(
              width: 280,
              child: Card(
                color: const Color(0xFFFFF6DD),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DealDetailPage(slug: item.slug),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.local_offer_rounded,
                          color: Color(0xFFE08A00),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              '${item.finalPrice} جنيه',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            Text('متبقي ${item.daysRemaining} يوم'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            height: 210,
            decoration: BoxDecoration(
              color: const Color(0xFFE1E9E5),
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          const SizedBox(height: 26),
          const LinearProgressIndicator(),
        ],
      );
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'تعذر تحميل الصفحة الرئيسية',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'قد يستغرق الخادم التجريبي لحظات عند أول تشغيل. سنعيد الاتصال تلقائيًا، ويمكنك المحاولة مرة أخرى.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
}

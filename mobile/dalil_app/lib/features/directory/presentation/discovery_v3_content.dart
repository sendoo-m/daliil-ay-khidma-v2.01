import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/presentation/catalog_detail_pages.dart';
import '../data/business.dart';
import '../data/discovery_repository.dart';
import 'business_card.dart';

class DiscoveryV3Content extends StatelessWidget {
  const DiscoveryV3Content({
    required this.discovery,
    required this.categories,
    required this.history,
    required this.isArabic,
    required this.onSearch,
    required this.onCategory,
    required this.onRemoveHistory,
    required this.onClearHistory,
    super.key,
  });

  final AsyncValue<DiscoveryData> discovery;
  final List<Map<String, dynamic>> categories;
  final AsyncValue<List<String>> history;
  final bool isArabic;
  final ValueChanged<String> onSearch;
  final ValueChanged<int> onCategory;
  final ValueChanged<String> onRemoveHistory;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    final recent = history.valueOrNull ?? const <String>[];
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          if (recent.isNotEmpty) ...[
            _Title(
              icon: Icons.history_rounded,
              title: isArabic ? 'عمليات البحث الأخيرة' : 'Recent searches',
              action: isArabic ? 'مسح الكل' : 'Clear all',
              onAction: onClearHistory,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recent.take(8).map((item) => InputChip(
                    avatar: const Icon(Icons.history_rounded, size: 17),
                    label: Text(item),
                    onPressed: () => onSearch(item),
                    onDeleted: () => onRemoveHistory(item),
                  )).toList(growable: false),
            ),
            const SizedBox(height: 26),
          ],
          _Title(
            icon: Icons.grid_view_rounded,
            title: isArabic ? 'استكشف الأقسام' : 'Explore categories',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 102,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.take(10).length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = categories[index];
                final id = item['id'] as int?;
                final label = '${item[isArabic ? 'name_ar' : 'name_en'] ?? item['name_ar'] ?? item['name_en'] ?? ''}';
                return SizedBox(
                  width: 104,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: id == null ? null : () => onCategory(id),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.category_rounded, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 26),
          discovery.when(
            loading: () => const _LoadingSections(),
            error: (_, __) => _FallbackSearches(
              isArabic: isArabic,
              onSearch: onSearch,
            ),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PopularSearches(
                  items: isArabic ? data.popularSearchesAr : data.popularSearchesEn,
                  isArabic: isArabic,
                  onSearch: onSearch,
                ),
                if (data.trendingBusinesses.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _BusinessSection(
                    title: isArabic ? 'الأكثر رواجًا' : 'Trending businesses',
                    icon: Icons.local_fire_department_rounded,
                    items: data.trendingBusinesses,
                  ),
                ],
                if (data.recommendedBusinesses.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _BusinessSection(
                    title: isArabic ? 'موصى به لك' : 'Recommended for you',
                    icon: Icons.auto_awesome_rounded,
                    items: data.recommendedBusinesses,
                  ),
                ],
                if (data.popularProducts.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _ProductSection(
                    title: isArabic ? 'منتجات وخدمات شائعة' : 'Popular products & services',
                    items: data.popularProducts,
                    isArabic: isArabic,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.icon, required this.title, this.action, this.onAction});
  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ],
      );
}

class _PopularSearches extends StatelessWidget {
  const _PopularSearches({required this.items, required this.isArabic, required this.onSearch});
  final List<String> items;
  final bool isArabic;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Title(
            icon: Icons.trending_up_rounded,
            title: isArabic ? 'الأكثر بحثًا' : 'Popular searches',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: items.map((item) => ActionChip(
                  avatar: const Icon(Icons.search_rounded, size: 17),
                  label: Text(item),
                  onPressed: () => onSearch(item),
                )).toList(growable: false),
          ),
        ],
      );
}

class _BusinessSection extends StatelessWidget {
  const _BusinessSection({required this.title, required this.icon, required this.items});
  final String title;
  final IconData icon;
  final List<Business> items;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Title(icon: icon, title: title),
          const SizedBox(height: 10),
          ...items.take(5).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BusinessCard(business: item),
              )),
        ],
      );
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({required this.title, required this.items, required this.isArabic});
  final String title;
  final List<ProductSummary> items;
  final bool isArabic;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Title(icon: Icons.shopping_bag_rounded, title: title),
          const SizedBox(height: 10),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.take(8).length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  width: 176,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => ProductDetailPage(slug: item.slug)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: item.image == null
                                ? const Center(child: Icon(Icons.inventory_2_outlined, size: 42))
                                : Image.network(item.image!, fit: BoxFit.cover),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text(isArabic ? '${item.price} ج.م' : '${item.price} EGP', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
}

class _LoadingSections extends StatelessWidget {
  const _LoadingSections();

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 96,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(child: LinearProgressIndicator()),
          ),
        ),
      );
}

class _FallbackSearches extends StatelessWidget {
  const _FallbackSearches({required this.isArabic, required this.onSearch});
  final bool isArabic;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) => _PopularSearches(
        items: isArabic
            ? const ['مطاعم', 'كافيهات', 'صيدليات', 'سباك', 'كهربائي', 'عروض']
            : const ['Restaurants', 'Cafes', 'Pharmacies', 'Plumber', 'Electrician', 'Deals'],
        isArabic: isArabic,
        onSearch: onSearch,
      );
}

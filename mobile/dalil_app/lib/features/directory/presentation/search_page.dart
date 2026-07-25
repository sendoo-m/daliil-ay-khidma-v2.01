import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/providers.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/presentation/catalog_detail_pages.dart';
import '../../home/data/home_repository.dart';
import '../data/business.dart';
import 'business_card.dart';

enum _SearchKind { businesses, products }

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({
    this.embedded = false,
    this.initialQuery = '',
    this.initialCategoryId,
    super.key,
  });

  final bool embedded;
  final String initialQuery;
  final int? initialCategoryId;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);
  late String _query = widget.initialQuery.trim();
  late int? _categoryId = widget.initialCategoryId;
  int? _governorateId;
  String? _businessType;
  String? _productType;
  double? _minRating;
  double? _minPrice;
  double? _maxPrice;
  var _kind = _SearchKind.businesses;
  var _comparePrices = false;
  var _revision = 0;
  Timer? _searchDebounce;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';
  String _tr(String ar, String en) => _isArabic ? ar : en;

  int get _filterCount => [
        _categoryId,
        _governorateId,
        _businessType,
        _productType,
        _minRating,
        _minPrice,
        _maxPrice,
      ].where((value) => value != null).length;

  bool get _hasFilters => _filterCount > 0;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 420), _runSearch);
  }

  void _runSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _query = _controller.text.trim();
      _revision++;
    });
  }

  void _clearFilters() => setState(() {
        _categoryId = widget.initialCategoryId;
        _governorateId = null;
        _businessType = null;
        _productType = null;
        _minRating = null;
        _minPrice = null;
        _maxPrice = null;
        _comparePrices = false;
        _revision++;
      });

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeProvider);
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        title: Text(_tr('البحث الذكي', 'Smart search')),
        actions: [
          IconButton(
            tooltip: _tr('الفلاتر', 'Filters'),
            onPressed: home.valueOrNull == null
                ? null
                : () => _showFilters(home.requireValue),
            icon: Badge(
              isLabelVisible: _filterCount > 0,
              label: Text('$_filterCount'),
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchHeader(
            controller: _controller,
            isArabic: _isArabic,
            onChanged: () {
              setState(() {});
              _scheduleSearch();
            },
            onSearch: _runSearch,
            onClear: () {
              _controller.clear();
              _runSearch();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: SegmentedButton<_SearchKind>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _SearchKind.businesses,
                  icon: const Icon(Icons.storefront_rounded),
                  label: Text(_tr('الأنشطة', 'Businesses')),
                ),
                ButtonSegment(
                  value: _SearchKind.products,
                  icon: const Icon(Icons.shopping_bag_rounded),
                  label: Text(_tr('المنتجات والخدمات', 'Products & services')),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (value) => setState(() {
                _kind = value.first;
                _comparePrices = false;
                _revision++;
              }),
            ),
          ),
          _QuickActions(
            isArabic: _isArabic,
            filterCount: _filterCount,
            productsSelected: _kind == _SearchKind.products,
            comparing: _comparePrices,
            onFilter: home.valueOrNull == null
                ? null
                : () => _showFilters(home.requireValue),
            onClear: _clearFilters,
            onCompare: () => setState(() {
              _comparePrices = !_comparePrices;
              _revision++;
            }),
          ),
          Expanded(
            child: (_query.isEmpty && !_hasFilters)
                ? _SearchHint(isArabic: _isArabic)
                : _kind == _SearchKind.businesses
                    ? _businessResults()
                    : _productResults(),
          ),
        ],
      ),
    );
  }

  Widget _businessResults() => FutureBuilder<List<Business>>(
        key: ValueKey('business-$_revision'),
        future: ref.read(businessRepositoryProvider).search(
              _query,
              categoryId: _categoryId,
              governorateId: _governorateId,
              businessType: _businessType,
              minRating: _minRating,
              ordering: _minRating == null ? '-is_featured' : '-average_rating',
            ),
        builder: (context, snapshot) => _ResultsFrame<Business>(
          snapshot: snapshot,
          isArabic: _isArabic,
          itemBuilder: (item) => BusinessCard(business: item),
        ),
      );

  Widget _productResults() => FutureBuilder<List<ProductSummary>>(
        key: ValueKey('product-$_revision-$_comparePrices'),
        future: ref.read(catalogRepositoryProvider).searchProducts(
              _query,
              categoryId: _categoryId,
              governorateId: _governorateId,
              productType: _productType,
              minPrice: _minPrice,
              maxPrice: _maxPrice,
              ordering: _comparePrices ? 'price' : '-is_featured',
            ),
        builder: (context, snapshot) => _ResultsFrame<ProductSummary>(
          snapshot: snapshot,
          isArabic: _isArabic,
          header: _comparePrices && (snapshot.data?.isNotEmpty ?? false)
              ? _ComparisonHeader(items: snapshot.data!, isArabic: _isArabic)
              : null,
          itemBuilder: (item) => _ProductResultCard(
            item: item,
            isArabic: _isArabic,
            cheapest: _comparePrices &&
                snapshot.data!.first.numericPrice == item.numericPrice,
          ),
        ),
      );

  Future<void> _showFilters(HomeData home) async {
    var categoryId = _categoryId;
    var governorateId = _governorateId;
    var businessType = _businessType;
    var productType = _productType;
    var minRating = _minRating;
    final minPriceController =
        TextEditingController(text: _minPrice?.toStringAsFixed(0) ?? '');
    final maxPriceController =
        TextEditingController(text: _maxPrice?.toStringAsFixed(0) ?? '');

    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.tune_rounded,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tr('تصفية النتائج', 'Filter results'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              _tr('اختر ما يناسب بحثك', 'Refine what you want to find'),
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  DropdownButtonFormField<int?>(
                    initialValue: categoryId,
                    decoration: InputDecoration(
                      labelText: _tr('القسم', 'Category'),
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(_tr('كل الأقسام', 'All categories')),
                      ),
                      ...home.categories.map(
                        (item) => DropdownMenuItem(
                          value: item['id'] as int,
                          child: Text(
                            '${item[_isArabic ? 'name_ar' : 'name_en'] ?? item['name_ar'] ?? ''}',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => categoryId = value),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int?>(
                    initialValue: governorateId,
                    decoration: InputDecoration(
                      labelText: _tr('المحافظة', 'Governorate'),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(_tr('كل المحافظات', 'All governorates')),
                      ),
                      ...home.governorates.map(
                        (item) => DropdownMenuItem(
                          value: item['id'] as int,
                          child: Text(
                            '${item[_isArabic ? 'name_ar' : 'name_en'] ?? item['name_ar'] ?? ''}',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => governorateId = value),
                  ),
                  const SizedBox(height: 14),
                  if (_kind == _SearchKind.businesses) ...[
                    DropdownButtonFormField<String?>(
                      initialValue: businessType,
                      decoration: InputDecoration(
                        labelText: _tr('نوع النشاط', 'Business type'),
                        prefixIcon: const Icon(Icons.store_mall_directory_outlined),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(_tr('الكل', 'All'))),
                        DropdownMenuItem(value: 'shop', child: Text(_tr('محلات', 'Shops'))),
                        DropdownMenuItem(value: 'craft', child: Text(_tr('حرفيون', 'Crafts'))),
                        DropdownMenuItem(value: 'public', child: Text(_tr('خدمات عامة', 'Public services'))),
                      ],
                      onChanged: (value) =>
                          setModalState(() => businessType = value),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<double?>(
                      initialValue: minRating,
                      decoration: InputDecoration(
                        labelText: _tr('أقل تقييم', 'Minimum rating'),
                        prefixIcon: const Icon(Icons.star_outline_rounded),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(_tr('أي تقييم', 'Any rating'))),
                        DropdownMenuItem(value: 3, child: Text(_tr('3 نجوم فأكثر', '3+ stars'))),
                        DropdownMenuItem(value: 4, child: Text(_tr('4 نجوم فأكثر', '4+ stars'))),
                        DropdownMenuItem(value: 4.5, child: Text(_tr('4.5 نجمة فأكثر', '4.5+ stars'))),
                      ],
                      onChanged: (value) =>
                          setModalState(() => minRating = value),
                    ),
                  ] else ...[
                    DropdownButtonFormField<String?>(
                      initialValue: productType,
                      decoration: InputDecoration(
                        labelText: _tr('النوع', 'Type'),
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(_tr('الكل', 'All'))),
                        DropdownMenuItem(value: 'product', child: Text(_tr('منتجات', 'Products'))),
                        DropdownMenuItem(value: 'service', child: Text(_tr('خدمات', 'Services'))),
                      ],
                      onChanged: (value) =>
                          setModalState(() => productType = value),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: _tr('أقل سعر', 'Min price')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: _tr('أعلى سعر', 'Max price')),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.search_rounded),
                    label: Text(_tr('عرض النتائج', 'Show results')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(_tr('إلغاء', 'Cancel')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final minPrice = double.tryParse(minPriceController.text);
    final maxPrice = double.tryParse(maxPriceController.text);
    minPriceController.dispose();
    maxPriceController.dispose();
    if (apply != true || !mounted) return;
    setState(() {
      _categoryId = categoryId;
      _governorateId = governorateId;
      _businessType = businessType;
      _productType = productType;
      _minRating = minRating;
      _minPrice = minPrice;
      _maxPrice = maxPrice;
      _revision++;
    });
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.isArabic,
    required this.onChanged,
    required this.onSearch,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isArabic;
  final VoidCallback onChanged;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'ماذا تبحث عنه اليوم؟' : 'What are you looking for today?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isArabic
                  ? 'ابحث في المحلات والمنتجات والخدمات وقارن الأسعار.'
                  : 'Search businesses, products and services, then compare prices.',
              style: const TextStyle(color: Color(0xFFF0EFFF), height: 1.6),
            ),
            const SizedBox(height: 15),
            SearchBar(
              controller: controller,
              hintText: isArabic ? 'اسم محل، منتج أو خدمة' : 'Business, product or service',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (controller.text.isNotEmpty)
                  IconButton(
                    tooltip: isArabic ? 'مسح' : 'Clear',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  ),
                IconButton(
                  tooltip: isArabic ? 'بحث' : 'Search',
                  onPressed: onSearch,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
              onChanged: (_) => onChanged(),
              onSubmitted: (_) => onSearch(),
            ),
          ],
        ),
      );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.isArabic,
    required this.filterCount,
    required this.productsSelected,
    required this.comparing,
    required this.onFilter,
    required this.onClear,
    required this.onCompare,
  });

  final bool isArabic;
  final int filterCount;
  final bool productsSelected;
  final bool comparing;
  final VoidCallback? onFilter;
  final VoidCallback onClear;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 58,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          scrollDirection: Axis.horizontal,
          children: [
            ActionChip(
              avatar: const Icon(Icons.tune_rounded, size: 18),
              label: Text(
                filterCount == 0
                    ? (isArabic ? 'الفلاتر' : 'Filters')
                    : (isArabic ? '$filterCount فلاتر' : '$filterCount filters'),
              ),
              onPressed: onFilter,
            ),
            if (productsSelected) ...[
              const SizedBox(width: 8),
              FilterChip(
                selected: comparing,
                avatar: const Icon(Icons.compare_arrows_rounded, size: 18),
                label: Text(
                  comparing
                      ? (isArabic ? 'إنهاء المقارنة' : 'Stop comparing')
                      : (isArabic ? 'مقارنة الأسعار' : 'Compare prices'),
                ),
                onSelected: (_) => onCompare(),
              ),
            ],
            if (filterCount > 0) ...[
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: Text(isArabic ? 'مسح الكل' : 'Clear all'),
                onPressed: onClear,
              ),
            ],
          ],
        ),
      );
}

class _ResultsFrame<T> extends StatelessWidget {
  const _ResultsFrame({
    required this.snapshot,
    required this.itemBuilder,
    required this.isArabic,
    this.header,
  });

  final AsyncSnapshot<List<T>> snapshot;
  final Widget Function(T item) itemBuilder;
  final bool isArabic;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        title: isArabic ? 'تعذر تنفيذ البحث' : 'Search failed',
        subtitle: isArabic ? 'تحقق من الاتصال وحاول مرة أخرى' : 'Check your connection and try again',
      );
    }
    final items = snapshot.data ?? const [];
    if (items.isEmpty) {
      return _MessageState(
        icon: Icons.search_off_rounded,
        title: isArabic ? 'لا توجد نتائج' : 'No results',
        subtitle: isArabic ? 'جرّب كلمة أخرى أو وسّع نطاق الفلاتر' : 'Try another term or broaden the filters',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      itemCount: items.length + (header == null ? 0 : 1),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        if (header != null && index == 0) return header!;
        return itemBuilder(items[index - (header == null ? 0 : 1)]);
      },
    );
  }
}

class _ComparisonHeader extends StatelessWidget {
  const _ComparisonHeader({required this.items, required this.isArabic});
  final List<ProductSummary> items;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final lowest = items.first.numericPrice;
    final highest = items.last.numericPrice;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: .22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_rounded, color: AppColors.primary, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? '${items.length} أسعار مرتبة من الأقل' : '${items.length} prices sorted low to high',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (highest.isFinite && lowest.isFinite && highest > lowest)
                  Text(
                    isArabic
                        ? 'يمكنك توفير ${(highest - lowest).toStringAsFixed(0)} ج.م'
                        : 'You can save ${(highest - lowest).toStringAsFixed(0)} EGP',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductResultCard extends StatelessWidget {
  const _ProductResultCard({
    required this.item,
    required this.cheapest,
    required this.isArabic,
  });

  final ProductSummary item;
  final bool cheapest;
  final bool isArabic;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailPage(slug: item.slug),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: item.image == null
                      ? Container(
                          width: 82,
                          height: 82,
                          color: AppColors.surfaceMuted,
                          child: const Icon(Icons.inventory_2_outlined,
                              color: AppColors.primary),
                        )
                      : Image.network(
                          item.image!,
                          width: 82,
                          height: 82,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.square(
                            dimension: 82,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (cheapest)
                            Chip(
                              label: Text(isArabic ? 'الأقل سعرًا' : 'Lowest'),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      Text(item.businessName,
                          style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 7),
                      Text(
                        isArabic ? '${item.price} ج.م' : '${item.price} EGP',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left_rounded),
              ],
            ),
          ),
        ),
      );
}

class _SearchHint extends StatelessWidget {
  const _SearchHint({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) => _MessageState(
        icon: Icons.manage_search_rounded,
        title: isArabic ? 'ابحث في دليل أي خدمة' : 'Search Daliil Ay Khidma',
        subtitle: isArabic
            ? 'اكتب اسم محل أو منتج أو خدمة، أو استخدم الفلاتر المتقدمة'
            : 'Enter a business, product or service, or use advanced filters',
      );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 42, color: AppColors.primary),
                ),
                const SizedBox(height: 17),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/providers.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/presentation/catalog_detail_pages.dart';
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
  var _kind = _SearchKind.businesses;
  var _revision = 0;
  Timer? _debounce;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';
  String _tr(String ar, String en) => _isArabic ? ar : en;

  List<String> get _popularSearches => _isArabic
      ? const ['مطاعم', 'كافيهات', 'سباك', 'كهربائي', 'صيدليات', 'عروض']
      : const ['Restaurants', 'Cafes', 'Plumber', 'Electrician', 'Pharmacies', 'Deals'];

  @override
  void initState() {
    super.initState();
    if (_query.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchHistoryProvider.notifier).add(_query);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _submit(value, dismissKeyboard: false);
    });
  }

  void _submit(String value, {bool dismissKeyboard = true}) {
    final normalized = value.trim();
    if (dismissKeyboard) FocusScope.of(context).unfocus();
    setState(() {
      _query = normalized;
      _revision++;
    });
    if (normalized.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).add(normalized);
    }
  }

  void _selectSuggestion(String value) {
    _controller
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    _submit(value);
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _query = '';
      _revision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeProvider);
    final history = ref.watch(searchHistoryProvider);
    final discoveryMode = _query.isEmpty && _categoryId == null;

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(_tr('البحث والاستكشاف', 'Search & discovery')),
              centerTitle: false,
            ),
      body: SafeArea(
        top: widget.embedded,
        child: Column(
          children: [
            _SearchHero(
              controller: _controller,
              isArabic: _isArabic,
              onChanged: _onChanged,
              onSubmitted: (value) => _submit(value),
              onClear: _clearSearch,
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
                  _revision++;
                }),
              ),
            ),
            home.maybeWhen(
              data: (data) => _CategoryStrip(
                categories: data.categories,
                selectedId: _categoryId,
                isArabic: _isArabic,
                onSelected: (id) => setState(() {
                  _categoryId = id;
                  _revision++;
                }),
              ),
              orElse: () => const SizedBox(height: 16),
            ),
            Expanded(
              child: discoveryMode
                  ? _DiscoveryContent(
                      isArabic: _isArabic,
                      history: history,
                      popular: _popularSearches,
                      typedValue: _controller.text,
                      onSelect: _selectSuggestion,
                      onRemove: (value) => ref
                          .read(searchHistoryProvider.notifier)
                          .remove(value),
                      onClearHistory: () => ref
                          .read(searchHistoryProvider.notifier)
                          .clear(),
                    )
                  : _kind == _SearchKind.businesses
                      ? _businessResults()
                      : _productResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _businessResults() => FutureBuilder<List<Business>>(
        key: ValueKey('business-$_revision-$_query-$_categoryId'),
        future: ref.read(businessRepositoryProvider).search(
              _query,
              categoryId: _categoryId,
              ordering: '-is_featured',
            ),
        builder: (context, snapshot) => _ResultsFrame<Business>(
          snapshot: snapshot,
          isArabic: _isArabic,
          itemBuilder: (item) => BusinessCard(business: item),
        ),
      );

  Widget _productResults() => FutureBuilder<List<ProductSummary>>(
        key: ValueKey('product-$_revision-$_query-$_categoryId'),
        future: ref.read(catalogRepositoryProvider).searchProducts(
              _query,
              categoryId: _categoryId,
              ordering: '-is_featured',
            ),
        builder: (context, snapshot) => _ResultsFrame<ProductSummary>(
          snapshot: snapshot,
          isArabic: _isArabic,
          itemBuilder: (item) => _ProductResultCard(
            item: item,
            isArabic: _isArabic,
          ),
        ),
      );
}

class _SearchHero extends StatelessWidget {
  const _SearchHero({
    required this.controller,
    required this.isArabic,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isArabic;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        decoration: const BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'ماذا تبحث عنه اليوم؟' : 'What are you looking for?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              isArabic
                  ? 'اكتشف الأنشطة والمنتجات والخدمات القريبة منك'
                  : 'Discover businesses, products and services near you',
              style: TextStyle(color: Colors.white.withValues(alpha: .84)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: isArabic
                    ? 'اسم نشاط، منتج أو خدمة...'
                    : 'Business, product or service...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: isArabic ? 'مسح' : 'Clear',
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      );
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selectedId,
    required this.isArabic,
    required this.onSelected,
  });

  final List<Map<String, dynamic>> categories;
  final int? selectedId;
  final bool isArabic;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 58,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: [
            ChoiceChip(
              selected: selectedId == null,
              label: Text(isArabic ? 'الكل' : 'All'),
              avatar: const Icon(Icons.apps_rounded, size: 18),
              onSelected: (_) => onSelected(null),
            ),
            ...categories.take(12).map((item) {
              final id = item['id'] as int?;
              final name = '${item[isArabic ? 'name_ar' : 'name_en'] ?? item['name_ar'] ?? item['name_en'] ?? ''}';
              return Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: ChoiceChip(
                  selected: selectedId == id,
                  label: Text(name),
                  onSelected: (_) => onSelected(id),
                ),
              );
            }),
          ],
        ),
      );
}

class _DiscoveryContent extends StatelessWidget {
  const _DiscoveryContent({
    required this.isArabic,
    required this.history,
    required this.popular,
    required this.typedValue,
    required this.onSelect,
    required this.onRemove,
    required this.onClearHistory,
  });

  final bool isArabic;
  final AsyncValue<List<String>> history;
  final List<String> popular;
  final String typedValue;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    final recent = history.valueOrNull ?? const <String>[];
    final needle = typedValue.trim().toLowerCase();
    final suggestions = <String>{...recent, ...popular}
        .where((item) => needle.isEmpty || item.toLowerCase().contains(needle))
        .take(6)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (needle.isNotEmpty && suggestions.isNotEmpty) ...[
          _SectionTitle(
            title: isArabic ? 'اقتراحات البحث' : 'Search suggestions',
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: 10),
          ...suggestions.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.north_west_rounded),
                title: Text(item),
                trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
                onTap: () => onSelect(item),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (recent.isNotEmpty) ...[
          _SectionTitle(
            title: isArabic ? 'عمليات البحث الأخيرة' : 'Recent searches',
            icon: Icons.history_rounded,
            actionLabel: isArabic ? 'مسح الكل' : 'Clear all',
            onAction: onClearHistory,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recent
                .map(
                  (item) => InputChip(
                    avatar: const Icon(Icons.history_rounded, size: 17),
                    label: Text(item),
                    onPressed: () => onSelect(item),
                    onDeleted: () => onRemove(item),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 24),
        ],
        _SectionTitle(
          title: isArabic ? 'الأكثر بحثًا' : 'Popular searches',
          icon: Icons.trending_up_rounded,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: popular
              .map(
                (item) => ActionChip(
                  avatar: const Icon(Icons.search_rounded, size: 17),
                  label: Text(item),
                  onPressed: () => onSelect(item),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tips_and_updates_rounded,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'ابحث بطريقة أسرع' : 'Search faster',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isArabic
                          ? 'اكتب اسم المكان أو الخدمة، ثم اختر القسم لتضييق النتائج.'
                          : 'Type a place or service, then choose a category to narrow results.',
                      style: const TextStyle(color: AppColors.muted, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      );
}

class _ResultsFrame<T> extends StatelessWidget {
  const _ResultsFrame({
    required this.snapshot,
    required this.itemBuilder,
    required this.isArabic,
  });

  final AsyncSnapshot<List<T>> snapshot;
  final Widget Function(T item) itemBuilder;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const _SearchSkeleton();
    }
    if (snapshot.hasError) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        title: isArabic ? 'تعذر تنفيذ البحث' : 'Search failed',
        subtitle: isArabic
            ? 'تحقق من الاتصال وحاول مرة أخرى'
            : 'Check your connection and try again',
      );
    }
    final items = snapshot.data ?? const [];
    if (items.isEmpty) {
      return _MessageState(
        icon: Icons.search_off_rounded,
        title: isArabic ? 'لا توجد نتائج' : 'No results found',
        subtitle: isArabic
            ? 'جرّب كلمة مختلفة أو اختر قسمًا آخر'
            : 'Try another term or choose a different category',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => itemBuilder(items[index]),
      ),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 112,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(child: LinearProgressIndicator()),
        ),
      );
}

class _ProductResultCard extends StatelessWidget {
  const _ProductResultCard({required this.item, required this.isArabic});

  final ProductSummary item;
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
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
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
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
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

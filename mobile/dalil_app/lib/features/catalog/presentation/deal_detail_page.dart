import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../auth/presentation/login_page.dart';
import '../../directory/presentation/business_detail_page.dart';
import '../data/catalog_models.dart';

class DealDetailPage extends ConsumerWidget {
  const DealDetailPage({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _DealDetailView(slug: slug);
}

class _DealDetailView extends ConsumerStatefulWidget {
  const _DealDetailView({required this.slug});

  final String slug;

  @override
  ConsumerState<_DealDetailView> createState() => _DealDetailViewState();
}

class _DealDetailViewState extends ConsumerState<_DealDetailView> {
  late Future<DealDetail> _future;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(catalogRepositoryProvider).dealDetail(widget.slug);
  }

  Future<void> _claim(DealDetail deal) async {
    final isAuthenticated =
        ref.read(authControllerProvider).valueOrNull ?? false;
    if (!isAuthenticated) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      );
      if (!mounted ||
          !(ref.read(authControllerProvider).valueOrNull ?? false)) {
        return;
      }
    }
    setState(() => _claiming = true);
    try {
      final claim =
          await ref.read(catalogRepositoryProvider).claimDeal(widget.slug);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.verified_outlined, size: 48),
          title: const Text('تم حجز العرض'),
          content: Text(
            'احتفظ برقم المطالبة وأظهره للمحل عند الاستفادة من العرض.\n\n'
            'رقم المطالبة: ${claim.id}',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تم'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر حجز العرض. ربما وصلت للحد المسموح أو انتهى العرض.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<DealDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(),
              body: _ErrorState(onRetry: () => setState(_load)),
            );
          }
          final deal = snapshot.data!;
          final summary = deal.summary;
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل العرض')),
            body: ListView(
              children: [
                _DealHero(deal: deal),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        summary.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      _DealPrice(deal: deal),
                      const SizedBox(height: 14),
                      _DealStatus(deal: deal),
                      if (deal.description.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _Section(
                          title: 'تفاصيل العرض',
                          icon: Icons.description_outlined,
                          child: Text(deal.description),
                        ),
                      ],
                      if (deal.terms.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _Section(
                          title: 'الشروط والأحكام',
                          icon: Icons.rule_outlined,
                          child: Text(deal.terms),
                        ),
                      ],
                      if (summary.businessName.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.storefront_outlined),
                            ),
                            title: const Text('مقدم من'),
                            subtitle: Text(summary.businessName),
                            trailing: summary.businessSlug.isEmpty
                                ? null
                                : const Icon(Icons.chevron_left),
                            onTap: summary.businessSlug.isEmpty
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => BusinessDetailPage(
                                          slug: summary.businessSlug,
                                        ),
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed:
                    deal.canClaim && !_claiming ? () => _claim(deal) : null,
                icon: _claiming
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.redeem),
                label: Text(
                  deal.isExpired
                      ? 'انتهى العرض'
                      : deal.isUpcoming
                          ? 'العرض يبدأ قريبًا'
                          : 'احجز العرض الآن',
                ),
              ),
            ),
          );
        },
      );
}

class _DealHero extends StatelessWidget {
  const _DealHero({required this.deal});

  final DealDetail deal;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          SizedBox(
            height: 245,
            width: double.infinity,
            child: deal.summary.image == null || deal.summary.image!.isEmpty
                ? ColoredBox(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.local_offer_outlined, size: 72),
                  )
                : Image.network(
                    deal.summary.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.local_offer_outlined, size: 72),
                    ),
                  ),
          ),
          PositionedDirectional(
            start: 16,
            bottom: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  deal.summary.typeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

class _DealPrice extends StatelessWidget {
  const _DealPrice({required this.deal});

  final DealDetail deal;

  @override
  Widget build(BuildContext context) {
    final summary = deal.summary;
    if (!summary.hasPrice) return Text(summary.typeLabel);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: [
        Text(
          _money(summary.finalPrice!),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
        ),
        if (summary.hasDiscount)
          Text(
            _money(summary.originalPrice!),
            style: const TextStyle(
              decoration: TextDecoration.lineThrough,
              fontSize: 16,
            ),
          ),
        if (deal.savingsAmount > 0)
          Chip(label: Text('وفّر ${_money(deal.savingsAmount)}')),
      ],
    );
  }
}

class _DealStatus extends StatelessWidget {
  const _DealStatus({required this.deal});

  final DealDetail deal;

  @override
  Widget build(BuildContext context) {
    final endDate = deal.endDate;
    final dateFormat = DateFormat('d MMMM y', 'ar');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 18,
          runSpacing: 12,
          children: [
            _StatusItem(
              icon: Icons.schedule,
              text: deal.isExpired
                  ? 'انتهى العرض'
                  : 'متبقي ${deal.summary.daysRemaining} يوم',
            ),
            if (endDate != null)
              _StatusItem(
                icon: Icons.event_outlined,
                text: 'حتى ${dateFormat.format(endDate.toLocal())}',
              ),
            if (deal.summary.isLimited)
              _StatusItem(
                icon: Icons.confirmation_number_outlined,
                text: 'متاح ${deal.summary.remainingUses} استخدام',
              ),
            _StatusItem(
              icon: Icons.person_outline,
              text: 'بحد أقصى ${deal.maxUsesPerUser} للمستخدم',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(text),
        ],
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 64),
              const SizedBox(height: 14),
              Text(
                'تعذر تحميل التفاصيل',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('تحقق من الاتصال ثم حاول مرة أخرى'),
              const SizedBox(height: 18),
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

String _money(double value) =>
    '${NumberFormat('#,##0.##', 'ar').format(value)} ج.م';

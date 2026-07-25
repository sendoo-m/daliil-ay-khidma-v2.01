import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../app/providers.dart';
import '../data/subscription_repository.dart';

final subscriptionPlansProvider = FutureProvider.autoDispose<List<SubscriptionPlan>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).plans(),
);

class SubscriptionPlansPage extends ConsumerWidget {
  const SubscriptionPlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(subscriptionPlansProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('خطط الاشتراك')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(subscriptionPlansProvider.future),
        child: plans.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView(
            children: [
              const SizedBox(height: 120),
              Icon(Icons.cloud_off_rounded, size: 58, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Center(child: Text('تعذر تحميل خطط الاشتراك')),
              const SizedBox(height: 14),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => ref.invalidate(subscriptionPlansProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ),
            ],
          ),
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
            children: [
              const _PricingHero(),
              const SizedBox(height: 22),
              if (items.isEmpty)
                const _EmptyPlans()
              else
                ...items.map((plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PlanCard(plan: plan),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricingHero extends StatelessWidget {
  const _PricingHero();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .24),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 38),
            SizedBox(height: 18),
            Text(
              'اختر الخطة المناسبة لنشاطك',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'ابدأ مجانًا وطوّر خطتك عندما تحتاج منتجات وعروض وتحليلات وظهور أقوى.',
              style: TextStyle(color: Color(0xFFF0EFFF), height: 1.7),
            ),
          ],
        ),
      );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final price = NumberFormat('#,##0.##', 'ar').format(plan.priceMonthly);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: plan.isPopular ? AppColors.primary : AppColors.border,
          width: plan.isPopular ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.displayName, style: Theme.of(context).textTheme.titleLarge),
                      if (plan.isPopular)
                        const Text(
                          'الأكثر اختيارًا',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(plan.description, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: Text('ج.م / شهر', style: TextStyle(color: AppColors.muted)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _Feature(text: plan.maxProducts == 0 ? 'منتجات غير محدودة' : '${plan.maxProducts} منتج'),
            _Feature(text: '${plan.maxImagesPerProduct} صور لكل منتج'),
            _Feature(text: '${plan.maxBusinessImages} صور لمعرض النشاط'),
            _Feature(text: 'إظهار الأسعار', enabled: plan.canShowPrices),
            _Feature(text: 'إنشاء العروض', enabled: plan.canCreateDeals),
            _Feature(text: 'لوحة التحليلات', enabled: plan.hasAnalytics),
            _Feature(text: 'أولوية في البحث', enabled: plan.featuredInSearch),
            _Feature(text: 'شارة موثّق', enabled: plan.hasVerifiedBadge),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => _showSubscribeInfo(context, plan),
              child: Text(plan.priceMonthly == 0 ? 'ابدأ مجانًا' : 'اختر الخطة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscribeInfo(BuildContext context, SubscriptionPlan plan) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('الاشتراك في ${plan.displayName}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            const Text(
              'إتمام الاشتراك والدفع متاح حاليًا من لوحة نشاطك على الموقع، وسيتم ربط الدفع المباشر داخل التطبيق في المرحلة التالية.',
              style: TextStyle(color: AppColors.muted, height: 1.7),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.text, this.enabled = true});
  final String text;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          children: [
            Icon(
              enabled ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
              size: 20,
              color: enabled ? AppColors.success : AppColors.muted,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: enabled ? AppColors.text : AppColors.muted),
              ),
            ),
          ],
        ),
      );
}

class _EmptyPlans extends StatelessWidget {
  const _EmptyPlans();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(36),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 52, color: AppColors.primary),
              SizedBox(height: 14),
              Text('لا توجد خطط نشطة حاليًا'),
            ],
          ),
        ),
      );
}

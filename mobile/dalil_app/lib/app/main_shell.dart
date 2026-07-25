import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/catalog/presentation/deals_page.dart';
import '../features/directory/presentation/favorites_page.dart';
import '../features/directory/presentation/search_page.dart';
import '../features/home/presentation/home_page_v3.dart';
import '../features/profile/presentation/profile_page.dart';
import 'app_theme.dart';
import 'providers.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  int _favoritesRevision = 0;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated =
        ref.watch(authControllerProvider).valueOrNull ?? false;
    final pages = <Widget>[
      HomePageV3(onSearchTap: () => setState(() => _index = 1)),
      const SearchPage(embedded: true),
      const DealsPage(),
      isAuthenticated
          ? FavoritesPage(
              key: ValueKey('favorites-$_favoritesRevision'),
              embedded: true,
            )
          : const _GuestGate(
              icon: Icons.favorite_rounded,
              eyebrow: 'مفضّلتك في مكان واحد',
              title: 'احفظ الأماكن التي تعجبك',
              description:
                  'سجّل دخولك لحفظ المحلات والخدمات والعودة إليها بسرعة في أي وقت.',
            ),
      isAuthenticated
          ? const ProfilePage(embedded: true)
          : const _GuestGate(
              icon: Icons.person_rounded,
              eyebrow: 'تجربة مخصّصة لك',
              title: 'مرحبًا بك في دليل أي خدمة',
              description:
                  'أنشئ حسابًا لإدارة المفضلة والتقييمات والإشعارات بسهولة.',
            ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() {
              _index = value;
              if (value == 3) _favoritesRevision++;
            }),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                selectedIcon: Icon(Icons.manage_search_rounded),
                label: 'البحث',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_offer_outlined),
                selectedIcon: Icon(Icons.local_offer_rounded),
                label: 'العروض',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_outline_rounded),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'المفضلة',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestGate extends StatelessWidget {
  const _GuestGate({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 42, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    eyebrow,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('تسجيل الدخول أو إنشاء حساب'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginPage(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

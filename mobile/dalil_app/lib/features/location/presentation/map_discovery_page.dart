import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_theme.dart';
import '../../../app/providers.dart';
import '../../directory/data/business.dart';
import '../../directory/presentation/business_detail_page.dart';
import '../data/location_service.dart';

const _mapStyle = 'https://tiles.openfreemap.org/styles/liberty';

class MapDiscoveryPage extends ConsumerStatefulWidget {
  const MapDiscoveryPage({super.key});

  @override
  ConsumerState<MapDiscoveryPage> createState() => _MapDiscoveryPageState();
}

class _MapDiscoveryPageState extends ConsumerState<MapDiscoveryPage> {
  final _searchController = TextEditingController();
  final Map<Circle, Business> _businessByCircle = {};

  MapLibreMapController? _mapController;
  UserCoordinates? _coordinates;
  List<Business> _allItems = const [];
  List<Business> _visibleItems = const [];
  Business? _selected;
  bool _loading = false;
  bool _styleLoaded = false;
  double _radius = 10;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNearby());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _buildMap()),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(20),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _applySearch,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن محل، منتج أو خدمة',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            tooltip: 'موقعي الحالي',
                            onPressed: _loading ? null : _loadNearby,
                            icon: const Icon(Icons.my_location_rounded),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _RadiusChip(
                            label: '5 كم',
                            selected: _radius == 5,
                            onTap: () => _changeRadius(5),
                          ),
                          _RadiusChip(
                            label: '10 كم',
                            selected: _radius == 10,
                            onTap: () => _changeRadius(10),
                          ),
                          _RadiusChip(
                            label: '20 كم',
                            selected: _radius == 20,
                            onTap: () => _changeRadius(20),
                          ),
                          _RadiusChip(
                            label: '50 كم',
                            selected: _radius == 50,
                            onTap: () => _changeRadius(50),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(),
                ),
              if (_message != null)
                Positioned(
                  top: 132,
                  left: 16,
                  right: 16,
                  child: _MessageCard(message: _message!),
                ),
              if (_visibleItems.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 14,
                  child: SizedBox(
                    height: 148,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      scrollDirection: Axis.horizontal,
                      itemCount: _visibleItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, index) {
                        final business = _visibleItems[index];
                        return _BusinessMapCard(
                          business: business,
                          selected: _selected?.id == business.id,
                          onTap: () => _selectBusiness(business),
                          onDetails: () => _openDetails(business),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildMap() {
    final coordinates = _coordinates;
    if (coordinates == null) {
      return const ColoredBox(
        color: AppColors.surfaceMuted,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'جارٍ تحديد موقعك لعرض الأنشطة القريبة على الخريطة',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return MapLibreMap(
      styleString: _mapStyle,
      initialCameraPosition: CameraPosition(
        target: LatLng(coordinates.latitude, coordinates.longitude),
        zoom: _zoomForRadius(_radius),
      ),
      myLocationEnabled: true,
      compassEnabled: true,
      onMapCreated: (controller) {
        _mapController = controller;
        controller.onCircleTapped.add(_onCircleTapped);
      },
      onStyleLoadedCallback: () {
        _styleLoaded = true;
        _refreshMarkers();
      },
    );
  }

  Future<void> _loadNearby() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final coordinates = await ref.read(locationServiceProvider).current();
      final items = await ref.read(businessRepositoryProvider).nearby(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            radiusKm: _radius,
          );
      if (!mounted) return;
      setState(() {
        _coordinates = coordinates;
        _allItems = items;
        _visibleItems = items;
        _selected = items.isEmpty ? null : items.first;
        _message = items.isEmpty ? 'لا توجد أنشطة ضمن النطاق المحدد' : null;
      });
      _applySearch(_searchController.text);
      await _refreshMarkers();
    } on LocationException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = switch (error.failure) {
          LocationFailure.serviceDisabled => 'فعّل خدمة الموقع ثم حاول مجددًا',
          LocationFailure.denied => 'لم يتم السماح باستخدام الموقع',
          LocationFailure.deniedForever =>
            'صلاحية الموقع مرفوضة دائمًا؛ فعّلها من إعدادات التطبيق',
        };
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applySearch(String value) {
    final query = value.trim().toLowerCase();
    final results = query.isEmpty
        ? _allItems
        : _allItems.where((business) {
            final searchable = [
              business.nameAr,
              business.nameEn,
              business.categoryName,
              business.description,
              business.address,
              business.area,
            ].join(' ').toLowerCase();
            return searchable.contains(query);
          }).toList(growable: false);

    setState(() {
      _visibleItems = results;
      _selected = results.isEmpty ? null : results.first;
      _message = results.isEmpty && _allItems.isNotEmpty
          ? 'لا توجد نتائج مطابقة داخل هذا النطاق'
          : null;
    });
    _refreshMarkers();
  }

  Future<void> _changeRadius(double radius) async {
    if (_radius == radius || _loading) return;
    setState(() => _radius = radius);
    await _loadNearby();
  }

  Future<void> _refreshMarkers() async {
    final controller = _mapController;
    final coordinates = _coordinates;
    if (!_styleLoaded || controller == null || coordinates == null) return;

    await controller.clearCircles();
    _businessByCircle.clear();
    for (final business in _visibleItems.where((item) => item.hasCoordinates)) {
      final isSelected = _selected?.id == business.id;
      final circle = await controller.addCircle(
        CircleOptions(
          geometry: LatLng(business.latitude!, business.longitude!),
          circleRadius: isSelected ? 12 : 9,
          circleColor: isSelected ? '#FFB23E' : '#0A8F68',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 3,
        ),
      );
      _businessByCircle[circle] = business;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(coordinates.latitude, coordinates.longitude),
        _zoomForRadius(_radius),
      ),
    );
  }

  void _onCircleTapped(Circle circle) {
    final business = _businessByCircle[circle];
    if (business != null) _selectBusiness(business);
  }

  Future<void> _selectBusiness(Business business) async {
    setState(() => _selected = business);
    await _refreshMarkers();
    if (_mapController != null && business.hasCoordinates) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(business.latitude!, business.longitude!),
        ),
      );
    }
  }

  void _openDetails(Business business) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BusinessDetailPage(slug: business.slug),
        ),
      );

  Future<void> _openDirections(Business business) async {
    if (!business.hasCoordinates) return;
    final uri = Uri.https('www.openstreetmap.org', '/directions', {
      'engine': 'fossgis_osrm_car',
      'route': '${business.latitude},${business.longitude}',
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  double _zoomForRadius(double radius) => switch (radius) {
        <= 5 => 13,
        <= 10 => 12,
        <= 20 => 11,
        _ => 10,
      };
}

class _RadiusChip extends StatelessWidget {
  const _RadiusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
}

class _BusinessMapCard extends StatelessWidget {
  const _BusinessMapCard({
    required this.business,
    required this.selected,
    required this.onTap,
    required this.onDetails,
  });

  final Business business;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 292,
        child: Card(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: business.logo == null
                        ? const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.primary,
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              business.logo!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.storefront_rounded,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          business.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          business.categoryName.isEmpty
                              ? business.area
                              : business.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 17,
                              color: AppColors.accentDark,
                            ),
                            Text(' ${business.rating.toStringAsFixed(1)}'),
                            if (business.distanceKm != null) ...[
                              const Text('  •  '),
                              Text('${business.distanceKm!.toStringAsFixed(1)} كم'),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'عرض التفاصيل',
                    onPressed: onDetails,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

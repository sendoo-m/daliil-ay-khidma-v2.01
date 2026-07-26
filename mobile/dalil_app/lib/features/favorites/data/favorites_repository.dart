import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../catalog/data/catalog_models.dart';
import '../../directory/data/business.dart';

final class FavoritesRepository {
  FavoritesRepository(this._dio, this._storage);

  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _keyProducts = 'fav_products';
  static const _keyDeals = 'fav_deals';

  // ------------------------ Businesses (API) ------------------------

  Future<List<Business>> businesses() async {
    final response = await _dio.get<Map<String, dynamic>>('favorites/');
    final results =
        response.data!['results'] as List<dynamic>? ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map((item) => item['business'])
        .whereType<Map<String, dynamic>>()
        .map(Business.fromJson)
        .toList(growable: false);
  }

  Future<bool> toggleBusiness(int businessId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'favorites/toggle/',
      data: {'business_id': businessId},
    );
    return response.data!['is_favorite'] as bool? ?? false;
  }

  // ------------------------ Products (Local) ------------------------

  Future<List<ProductSummary>> products() async {
    final raw = await _storage.read(key: _keyProducts);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ProductSummary.fromJson)
        .toList(growable: false);
  }

  Future<void> saveProducts(List<ProductSummary> items) async {
    final encoded = jsonEncode(
      items.map((p) => {
        'id': p.id,
        'name_ar': p.name,
        'slug': p.slug,
        'price': p.price,
        'old_price': p.oldPrice,
        'product_type': p.productType,
        'primary_image': p.image == null ? null : {'image': p.image},
        'business': {'name_ar': p.businessName, 'slug': p.businessSlug},
      }).toList(),
    );
    await _storage.write(key: _keyProducts, value: encoded);
  }

  // ------------------------ Deals (Local) ------------------------

  Future<List<DealSummary>> deals() async {
    final raw = await _storage.read(key: _keyDeals);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(DealSummary.fromJson)
        .toList(growable: false);
  }

  Future<void> saveDeals(List<DealSummary> items) async {
    final encoded = jsonEncode(
      items.map((d) => {
        'id': d.id,
        'title_ar': d.title,
        'slug': d.slug,
        'deal_type': d.dealType,
        'discount_percentage': d.discountPercentage,
        'days_remaining': d.daysRemaining,
        'is_valid': d.isValid,
        'is_featured': d.isFeatured,
        'original_price': d.originalPrice,
        'final_price': d.finalPrice,
        'image': d.image,
        'remaining_uses': d.remainingUses,
        'business': {'name_ar': d.businessName, 'slug': d.businessSlug},
      }).toList(),
    );
    await _storage.write(key: _keyDeals, value: encoded);
  }
}

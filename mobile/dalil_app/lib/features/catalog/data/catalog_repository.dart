import 'package:dio/dio.dart';

import 'catalog_models.dart';

final class CatalogRepository {
  CatalogRepository(this._dio);
  final Dio _dio;

  Future<ProductDetail> productDetail(String slug) async {
    final response = await _dio.get<Map<String, dynamic>>('products/$slug/');
    return ProductDetail.fromJson(response.data!);
  }

  Future<List<ProductSummary>> searchProducts(
    String query, {
    int? categoryId,
    int? businessId,
    int? governorateId,
    String? productType,
    double? minPrice,
    double? maxPrice,
    String ordering = 'price',
    int pageSize = 50,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'products/',
      queryParameters: {
        if (query.isNotEmpty) 'search': query,
        if (categoryId != null) 'category': categoryId,
        if (businessId != null) 'business': businessId,
        if (governorateId != null) 'governorate': governorateId,
        if (productType != null) 'product_type': productType,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        'ordering': ordering,
        'page_size': pageSize,
      },
    );
    final results = response.data?['results'] as List<dynamic>? ?? const [];
    return results
        .cast<Map<String, dynamic>>()
        .map(ProductSummary.fromJson)
        .toList(growable: false);
  }

  Future<List<DealSummary>> deals({
    String search = '',
    String ordering = '-created_at',
    int? businessId,
    int pageSize = 50,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'deals/',
      queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (businessId != null) 'business': businessId,
        'ordering': ordering,
        'page_size': pageSize,
      },
    );
    final results = response.data?['results'] as List<dynamic>? ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(DealSummary.fromJson)
        .toList(growable: false);
  }

  Future<DealDetail> dealDetail(String slug) async {
    final response = await _dio.get<Map<String, dynamic>>('deals/$slug/');
    return DealDetail.fromJson(response.data!);
  }

  Future<DealClaimResult> claimDeal(String slug) async {
    final response = await _dio.post<Map<String, dynamic>>('deals/$slug/claim/');
    return DealClaimResult.fromJson(response.data!);
  }
}

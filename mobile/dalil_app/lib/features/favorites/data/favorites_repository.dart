import 'package:dio/dio.dart';

import '../../directory/data/business.dart';

final class FavoritesRepository {
  FavoritesRepository(this._dio);

  final Dio _dio;

  Future<List<Business>> businesses() async {
    final response = await _dio.get<Map<String, dynamic>>('favorites/');
    final results = response.data?['results'] as List<dynamic>? ?? const [];
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
    return response.data?['is_favorite'] as bool? ?? false;
  }
}

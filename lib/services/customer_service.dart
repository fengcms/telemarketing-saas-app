/// 客户相关接口服务
///
/// 对应 api.md §客户管理（GET /api/tenant/customers）。
library;

import 'package:dio/dio.dart';
import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/api_constants.dart';
import 'package:telemarketing_app/models/customer.dart';

/// 客户相关接口服务
class CustomerService {
  final ApiClient _apiClient;

  CustomerService({required this._apiClient});

  /// 获取客户列表
  ///
  /// [scope] TE: mine，TM/TA: all
  /// [q] 搜索关键词（姓名/电话/公司），非空才传
  /// [level] 等级筛选 normal/important/vip/lost，非空才传
  /// [page] 页码，从 1 开始
  /// [size] 每页条数，默认 20
  /// [sort] 排序字段，默认 -convertedAt（转化日期降序）
  Future<({List<Customer> items, int total, int pages})> fetchCustomers({
    required String scope,
    String? q,
    String? level,
    int page = 1,
    int size = 20,
    String sort = '-convertedAt',
  }) async {
    try {
      final params = <String, dynamic>{
        'scope': scope,
        'erased': 0,
        'page': page,
        'size': size,
        'sort': sort,
      };
      if (q != null && q.isNotEmpty) params['q'] = q;
      if (level != null && level.isNotEmpty) params['level'] = level;

      final response = await _apiClient.dio.get(
        ApiConstants.customers,
        queryParameters: params,
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final body = data['data'] as Map? ?? {};
        final List<Customer> items = (body['items'] as List<dynamic>?)
                ?.map((e) => Customer.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        final pages = _toInt(body['pages']);
        return (
          items: items,
          total: _toInt(body['total']),
          pages: pages > 0 ? pages : 1,
        );
      }
      return (items: <Customer>[], total: 0, pages: 1);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

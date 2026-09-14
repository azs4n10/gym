import 'dart:convert';

import 'package:http/http.dart' as http;

/// A packaged product as Open Food Facts describes it. Values are per 100 g;
/// per serving too when the record carries a serving size.
class OffProduct {
  const OffProduct({
    required this.code,
    required this.name,
    required this.brand,
    required this.kcal100,
    required this.protein100,
    required this.fat100,
    required this.carbs100,
    this.servingSize,
    this.kcalServing,
    this.proteinServing,
    this.fatServing,
    this.carbsServing,
  });

  final String code;
  final String name;
  final String brand;
  final double kcal100;
  final double protein100;
  final double fat100;
  final double carbs100;
  final String? servingSize;
  final double? kcalServing;
  final double? proteinServing;
  final double? fatServing;
  final double? carbsServing;

  bool get hasServing =>
      servingSize != null && kcalServing != null && proteinServing != null && fatServing != null && carbsServing != null;

  static OffProduct? fromJson(Map<String, dynamic> p) {
    final n = (p['nutriments'] as Map<String, dynamic>?) ?? const {};
    double? d(String key) {
      final v = n[key];
      return v is num ? v.toDouble() : null;
    }

    final kcal = d('energy-kcal_100g');
    final name = (p['product_name_ja'] as String?)?.trim();
    final fallback = (p['product_name'] as String?)?.trim();
    final title = name != null && name.isNotEmpty ? name : (fallback ?? '');
    if (kcal == null || title.isEmpty) return null;
    return OffProduct(
      code: p['code'] as String? ?? '',
      name: title,
      brand: ((p['brands'] as String?) ?? '').split(',').first.trim(),
      kcal100: kcal,
      protein100: d('proteins_100g') ?? 0,
      fat100: d('fat_100g') ?? 0,
      carbs100: d('carbohydrates_100g') ?? 0,
      servingSize: (p['serving_size'] as String?)?.trim(),
      kcalServing: d('energy-kcal_serving'),
      proteinServing: d('proteins_serving'),
      fatServing: d('fat_serving'),
      carbsServing: d('carbohydrates_serving'),
    );
  }
}

/// Open Food Facts, the open (ODbL) database of packaged foods. Both calls
/// return nothing on any failure: the service is best effort, and the label
/// form is always there behind it. The servers answer 503 now and then, so a
/// request is tried three times, and a search falls back to the world site.
class OpenFoodFacts {
  OpenFoodFacts._();

  static const _fields =
      'code,product_name,product_name_ja,brands,serving_size,nutriments';
  static const _timeout = Duration(seconds: 8);

  static Future<Map<String, dynamic>?> _getJson(Uri uri) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final res = await http.get(uri).timeout(_timeout);
        if (res.statusCode == 200) {
          return jsonDecode(res.body) as Map<String, dynamic>;
        }
        if (res.statusCode == 404) return null;
      } catch (_) {
        // fall through to the next attempt
      }
      await Future<void>.delayed(Duration(milliseconds: 700 * (attempt + 1)));
    }
    return null;
  }

  static Future<OffProduct?> byBarcode(String code) async {
    final body = await _getJson(
      Uri.https('world.openfoodfacts.org', '/api/v2/product/$code.json', {'fields': _fields}),
    );
    if (body == null || body['status'] != 1) return null;
    return OffProduct.fromJson(body['product'] as Map<String, dynamic>);
  }

  static Future<List<OffProduct>> search(String query) async {
    for (final host in ['jp.openfoodfacts.org', 'world.openfoodfacts.org']) {
      final body = await _getJson(Uri.https(host, '/cgi/search.pl', {
        'search_terms': query,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '12',
        'fields': _fields,
      }));
      if (body == null) continue;
      final list = (body['products'] as List?) ?? const [];
      final found = [
        for (final p in list) ?OffProduct.fromJson(p as Map<String, dynamic>),
      ];
      if (found.isNotEmpty) return found;
    }
    return const [];
  }
}

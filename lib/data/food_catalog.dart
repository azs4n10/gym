import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/enums.dart';

/// One entry of the Standard Tables of Food Composition in Japan (MEXT,
/// 8th revised edition, 2023 supplement), per 100 g of the edible part.
class CatalogFood {
  const CatalogFood({
    required this.id,
    required this.group,
    required this.name,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  final String id;
  final String group;
  final String name;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;

  /// The table's 18 food groups, folded onto the app's tags.
  FoodTag get tag => switch (group) {
        '01' || '02' => FoodTag.staple,
        '04' || '10' || '11' || '12' => FoodTag.protein,
        '06' || '07' || '08' || '09' => FoodTag.vegetable,
        '13' || '16' => FoodTag.dairy,
        '03' || '15' => FoodTag.sweet,
        _ => FoodTag.dish,
      };
}

/// The bundled composition table, loaded once on first use.
class FoodCatalog {
  FoodCatalog._();

  static List<CatalogFood>? _items;
  static Future<List<CatalogFood>>? _loading;

  static Future<List<CatalogFood>> load() {
    if (_items != null) return Future.value(_items);
    return _loading ??= rootBundle.loadString('assets/data/mext_foods.json').then((raw) {
      final list = (jsonDecode(raw) as List)
          .map((e) => e as Map<String, dynamic>)
          .map((m) => CatalogFood(
                id: m['id'] as String,
                group: m['g'] as String,
                name: m['n'] as String,
                kcal: (m['k'] as num).toDouble(),
                protein: (m['p'] as num).toDouble(),
                fat: (m['f'] as num).toDouble(),
                carbs: (m['c'] as num).toDouble(),
              ))
          .toList(growable: false);
      _items = list;
      return list;
    });
  }

  /// Entries whose name contains every word of [query]. Katakana in the
  /// query is also tried as hiragana, since the table writes most names in
  /// hiragana.
  static List<CatalogFood> search(List<CatalogFood> items, String query, {int limit = 40}) {
    final words = query
        .toLowerCase()
        .split(RegExp(r'[\s　]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => [w, _toHiragana(w)])
        .toList();
    if (words.isEmpty) return const [];
    final out = <CatalogFood>[];
    for (final f in items) {
      final n = f.name.toLowerCase();
      if (words.every((alts) => alts.any(n.contains))) {
        out.add(f);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  static String _toHiragana(String s) => String.fromCharCodes(
        s.runes.map((r) => r >= 0x30A1 && r <= 0x30F6 ? r - 0x60 : r),
      );
}

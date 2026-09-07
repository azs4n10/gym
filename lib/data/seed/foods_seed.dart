import '../../l10n/strings.dart';
import '../../models/enums.dart';
import '../database.dart';

FoodsCompanion _f(String name, String serving, double kcal, double p,
        double f, double c, FoodTag tag) =>
    FoodsCompanion.insert(
      name: name,
      serving: serving,
      kcal: kcal,
      protein: p,
      fat: f,
      carbs: c,
      tag: tag.name,
    );

// Rough per-serving estimates; users are expected to replace them with label values
final List<FoodsCompanion> seedFoods = [
  _f('Chicken breast (skinless)', '100g', 105, 23.3, 1.9, 0.1, FoodTag.protein),
  _f('Chicken tender', '1 piece (45g)', 44, 10.7, 0.4, 0, FoodTag.protein),
  _f('Chicken thigh (skinless)', '100g', 113, 19.0, 5.0, 0, FoodTag.protein),
  _f('Salad chicken', '1 pack (110g)', 120, 24.0, 1.5, 1.0, FoodTag.protein),
  _f('Lean beef (round)', '100g', 140, 21.0, 6.0, 0.5, FoodTag.protein),
  _f('Pork loin', '100g', 248, 19.3, 19.2, 0.2, FoodTag.protein),
  _f('Salmon', '1 fillet (80g)', 99, 17.8, 3.3, 0.1, FoodTag.protein),
  _f('Canned mackerel (in water)', '1 can (190g)', 331, 39.7, 20.3, 0.4, FoodTag.protein),
  _f('Canned tuna (in water)', '1 can (70g)', 50, 12.0, 0.5, 0, FoodTag.protein),
  _f('Egg', '1 egg', 71, 6.1, 5.1, 0.2, FoodTag.protein),
  _f('Natto', '1 pack (45g)', 86, 7.4, 4.5, 5.4, FoodTag.protein),
  _f('Firm tofu', '1/2 block (150g)', 110, 10.5, 7.4, 2.3, FoodTag.protein),
  _f('Edamame', '50g', 59, 5.8, 3.1, 4.4, FoodTag.protein),
  _f('Protein shake', '1 scoop (30g)', 115, 22.0, 1.5, 3.5, FoodTag.protein),
  _f('Protein bar', '1 bar', 200, 15.0, 8.0, 20.0, FoodTag.protein),
  _f('Greek yogurt', '100g', 60, 10.0, 0, 5.0, FoodTag.dairy),
  _f('Milk', '200ml', 122, 6.6, 7.6, 9.6, FoodTag.dairy),
  _f('Soy milk', '200ml', 88, 7.2, 4.0, 6.2, FoodTag.dairy),
  _f('Cafe latte', '1 cup', 110, 6.0, 6.0, 9.0, FoodTag.dairy),
  _f('Black coffee', '1 cup', 4, 0.2, 0, 0.7, FoodTag.dairy),
  _f('Beer', '350ml', 140, 1.0, 0, 11.0, FoodTag.dairy),
  _f('White rice', '1 bowl (150g)', 234, 3.8, 0.5, 55.7, FoodTag.staple),
  _f('Brown rice', '1 bowl (150g)', 228, 4.2, 1.5, 53.0, FoodTag.staple),
  _f('Rice ball (salmon)', '1 piece', 180, 4.5, 1.5, 38.0, FoodTag.staple),
  _f('White bread', '1 thick slice', 149, 5.3, 2.5, 27.8, FoodTag.staple),
  _f('Oatmeal', '30g', 105, 4.1, 1.7, 20.7, FoodTag.staple),
  _f('Soba noodles', '1 serving (200g cooked)', 260, 9.6, 2.0, 52.0, FoodTag.staple),
  _f('Udon noodles', '1 serving (200g cooked)', 190, 5.2, 0.8, 43.0, FoodTag.staple),
  _f('Pasta', '1 serving (100g dry)', 347, 12.9, 1.8, 73.0, FoodTag.staple),
  _f('Sweet potato', '100g', 129, 0.9, 0.2, 31.0, FoodTag.staple),
  _f('Mochi', '1 piece (50g)', 112, 2.0, 0.3, 25.0, FoodTag.staple),
  _f('Banana', '1 banana', 93, 1.1, 0.2, 22.5, FoodTag.vegetable),
  _f('Apple', '1 apple', 133, 0.3, 0.5, 40.0, FoodTag.vegetable),
  _f('Avocado', '1/2 (70g)', 123, 1.5, 12.3, 5.6, FoodTag.vegetable),
  _f('Broccoli', '100g', 37, 5.4, 0.6, 6.6, FoodTag.vegetable),
  _f('Green salad', '1 plate', 20, 1.0, 0.2, 4.0, FoodTag.vegetable),
  _f('Mixed nuts', '25g', 155, 4.5, 13.5, 5.0, FoodTag.vegetable),
  _f('Miso soup', '1 bowl', 40, 3.0, 1.2, 5.0, FoodTag.dish),
  _f('Fried chicken (karaage)', '1 piece', 90, 5.0, 6.0, 3.0, FoodTag.dish),
  _f('Hamburger steak', '1 (150g)', 330, 20.0, 22.0, 12.0, FoodTag.dish),
  _f('Curry rice', '1 plate', 750, 17.0, 25.0, 110.0, FoodTag.dish),
  _f('Ramen', '1 bowl', 500, 20.0, 15.0, 70.0, FoodTag.dish),
  _f('Pizza', '1 slice', 250, 10.0, 10.0, 30.0, FoodTag.dish),
  _f('Chocolate', '1 square (5g)', 28, 0.4, 1.7, 2.6, FoodTag.sweet),
  _f('Shortcake', '1 slice', 350, 5.0, 20.0, 38.0, FoodTag.sweet),
  _f('Ice cream', '1 cup', 200, 3.5, 8.0, 28.0, FoodTag.sweet),
  _f('Pudding', '1 cup', 130, 4.0, 4.0, 20.0, FoodTag.sweet),
];

const Map<String, (String, String)> _foodJa = {
  'Chicken breast (skinless)': ('鶏むね肉（皮なし）', '100g'),
  'Chicken tender': ('鶏ささみ', '1本(45g)'),
  'Chicken thigh (skinless)': ('鶏もも肉（皮なし）', '100g'),
  'Salad chicken': ('サラダチキン', '1個(110g)'),
  'Lean beef (round)': ('牛もも肉（赤身）', '100g'),
  'Pork loin': ('豚ロース', '100g'),
  'Salmon': ('鮭', '1切れ(80g)'),
  'Canned mackerel (in water)': ('サバ缶（水煮）', '1缶(190g)'),
  'Canned tuna (in water)': ('ツナ缶（水煮）', '1缶(70g)'),
  'Egg': ('卵', '1個'),
  'Natto': ('納豆', '1パック(45g)'),
  'Firm tofu': ('木綿豆腐', '半丁(150g)'),
  'Edamame': ('枝豆', '50g'),
  'Protein shake': ('プロテイン', '1杯(30g)'),
  'Protein bar': ('プロテインバー', '1本'),
  'Greek yogurt': ('ギリシャヨーグルト', '100g'),
  'Milk': ('牛乳', '200ml'),
  'Soy milk': ('豆乳', '200ml'),
  'Cafe latte': ('カフェラテ', '1杯'),
  'Black coffee': ('コーヒー（ブラック）', '1杯'),
  'Beer': ('ビール', '350ml'),
  'White rice': ('白ごはん', '茶碗1杯(150g)'),
  'Brown rice': ('玄米ごはん', '茶碗1杯(150g)'),
  'Rice ball (salmon)': ('おにぎり（鮭）', '1個'),
  'White bread': ('食パン', '6枚切り1枚'),
  'Oatmeal': ('オートミール', '30g'),
  'Soba noodles': ('そば', '1人前(ゆで200g)'),
  'Udon noodles': ('うどん', '1玉(ゆで200g)'),
  'Pasta': ('パスタ', '1人前(乾100g)'),
  'Sweet potato': ('さつまいも', '100g'),
  'Mochi': ('餅', '1個(50g)'),
  'Banana': ('バナナ', '1本'),
  'Apple': ('りんご', '1個'),
  'Avocado': ('アボカド', '半分(70g)'),
  'Broccoli': ('ブロッコリー', '100g'),
  'Green salad': ('サラダ（葉物）', '1皿'),
  'Mixed nuts': ('ミックスナッツ', '25g'),
  'Miso soup': ('味噌汁', '1杯'),
  'Fried chicken (karaage)': ('唐揚げ', '1個'),
  'Hamburger steak': ('ハンバーグ', '1個(150g)'),
  'Curry rice': ('カレーライス', '1皿'),
  'Ramen': ('ラーメン', '1杯'),
  'Pizza': ('ピザ', '1切れ'),
  'Chocolate': ('チョコレート', '1かけ(5g)'),
  'Shortcake': ('ショートケーキ', '1個'),
  'Ice cream': ('アイスクリーム', '1個'),
  'Pudding': ('プリン', '1個'),
};

String foodName(Food f, L l) =>
    l.isJa && !f.isCustom ? (_foodJa[f.name]?.$1 ?? f.name) : f.name;

String foodServing(Food f, L l) =>
    l.isJa && !f.isCustom ? (_foodJa[f.name]?.$2 ?? f.serving) : f.serving;

String foodNameByStored(String stored, L l) =>
    l.isJa ? (_foodJa[stored]?.$1 ?? stored) : stored;

bool foodMatches(Food f, String query) {
  final q = query.toLowerCase();
  if (f.name.toLowerCase().contains(q)) return true;
  final ja = _foodJa[f.name];
  return ja != null && ja.$1.contains(query);
}

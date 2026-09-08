import 'package:intl/intl.dart';

String fmtKg(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

abstract class L {
  const L();

  String get code;
  bool get isJa => code == 'ja';

  String dateLong(DateTime d);
  String dateShort(DateTime d) => DateFormat('M/d', code).format(d);
  String dateWithWeekday(DateTime d);
  String weekday(DateTime d) => DateFormat('E', code).format(d);
  String monthYear(DateTime d);
  List<String> get weekdayHeaders;

  String get navHome;
  String get navWorkout;
  String get navCalendar;
  String get navBody;
  String get navMeals;

  String greeting(int hour);
  String get thisWeekGym;
  String perWeek(int goal);
  String get weekStreakLabel;
  String get thisMonthLabel;
  String get allTimeLabel;
  String weeks(int n);
  String times(int n);
  String get workoutInProgress;
  String exercisesAndSets(int ex, int sets);
  String get todayWorkoutDone;
  String get startTodayWorkout;
  String get todayMeals;
  String get p;
  String get f;
  String get c;
  String get protein;
  String get fat;
  String get carbs;
  String get calories;
  String get logWeight;
  String get todayPicks;
  String get nextMealIdeas;
  String get foodListEmpty;
  String get added;
  String get start;
  String get bodyweight;
  String planLine(String weight, int reps, int sets);

  String get workouts;
  String get exerciseList;
  String get startNew;
  String get continueWorkout;
  String get noWorkoutsYet;
  String get cardio;
  String setsSummary(int ex, int sets, String vol);
  String minutes(int m);

  String get deleteRecordQ;
  String get cancel;
  String get delete;
  String get sessionDeleted;
  String totalVolume(int kg);
  String get addExercise;
  String get finishWorkout;
  String get savedSynced;
  String get savedSyncFailed;
  String get saved;
  String get removeExercise;
  String lastTime(String sets);
  String best(String kg);
  String get addSet;
  String get memoHint;
  String get addCardio;
  String get duration;
  String get distance;
  String get burned;
  String get add;
  String get repsUnit;
  String get minUnit;

  String get pickExercise;
  String get newExercise;
  String get search;
  String get all;
  String get notFound;
  String get name;
  String get create;
  String get showAgain;
  String get hide;
  String lastSet(String kg, int reps);

  String get body;
  String get logAction;
  String get weight;
  String get bodyFat;
  String get avg7;
  String overDays(int n);
  String get trend;
  String get history;
  String get noRecords;
  String get save;
  String get chartHint;
  String get d30;
  String get d90;
  String get y1;
  String get syncFailed;

  String get calendar;
  String get streak;
  String get weekStreakShort;
  String get monthLabel;
  String get daysUnit;
  String get weeksUnit;
  String get timesUnit;
  String get gym;
  String get meals;
  String bodyLine(double w, double? f);

  String kcalLeft(int n);
  String kcalOver(int n);
  String get ideas;
  String get synced;
  String get sync;
  String macroLine(int kcal, int p, int f, int c);

  String get custom;
  String get amount;
  String get servingsUnit;
  String get servingHint;
  String get saveToList;
  String get remove;
  String oneServing(String s);
  String addTo(String slot);

  String get settings;
  String get profile;
  String get sexLabel;
  String get birthYear;
  String get height;
  String get goal;
  String get activity;
  String get daysPerWeek;
  String get targets;
  String get manual;
  String get theme;
  String get font;
  String get fontStandard;
  String get fontRounded;
  String get health;
  String get healthNotSupported;
  String get appleHealth;
  String get healthConnect;
  String get permissionDenied;
  String get foodDisclaimer;
  String get language;
}

class LEn extends L {
  const LEn();

  @override
  String get code => 'en';

  @override
  String dateLong(DateTime d) => DateFormat('EEE, MMM d', 'en').format(d);
  @override
  String dateWithWeekday(DateTime d) => DateFormat('M/d (EEE)', 'en').format(d);
  @override
  String monthYear(DateTime d) => DateFormat('MMMM yyyy', 'en').format(d);
  @override
  List<String> get weekdayHeaders => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  String get navHome => 'Home';
  @override
  String get navWorkout => 'Workout';
  @override
  String get navCalendar => 'Calendar';
  @override
  String get navBody => 'Body';
  @override
  String get navMeals => 'Meals';

  @override
  String greeting(int hour) {
    if (hour < 5) return 'Good evening';
    if (hour < 11) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  String get thisWeekGym => 'This week';
  @override
  String perWeek(int goal) => '/$goal';
  @override
  String get weekStreakLabel => 'Streak';
  @override
  String get thisMonthLabel => 'Month';
  @override
  String get allTimeLabel => 'Total';
  @override
  String weeks(int n) => '$n wk';
  @override
  String times(int n) => '$n';
  @override
  String get workoutInProgress => 'In progress';
  @override
  String exercisesAndSets(int ex, int sets) => '$ex ex · $sets sets';
  @override
  String get todayWorkoutDone => 'Done today';
  @override
  String get startTodayWorkout => 'Start workout';
  @override
  String get todayMeals => 'Meals';
  @override
  String get p => 'P';
  @override
  String get f => 'F';
  @override
  String get c => 'C';
  @override
  String get protein => 'Protein';
  @override
  String get fat => 'Fat';
  @override
  String get carbs => 'Carbs';
  @override
  String get calories => 'kcal';
  @override
  String get logWeight => 'Weight';
  @override
  String get todayPicks => 'Picks';
  @override
  String get nextMealIdeas => 'Meal ideas';
  @override
  String get foodListEmpty => 'No foods';
  @override
  String get added => 'Added';
  @override
  String get start => 'Start';
  @override
  String get bodyweight => 'BW';
  @override
  String planLine(String weight, int reps, int sets) => '$weight × $reps × $sets';

  @override
  String get workouts => 'Workouts';
  @override
  String get exerciseList => 'Exercises';
  @override
  String get startNew => 'New';
  @override
  String get continueWorkout => 'Continue';
  @override
  String get noWorkoutsYet => 'No workouts yet';
  @override
  String get cardio => 'Cardio';
  @override
  String setsSummary(int ex, int sets, String vol) => '$ex ex · $sets sets · $vol';
  @override
  String minutes(int m) => '$m min';

  @override
  String get deleteRecordQ => 'Delete this workout?';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get sessionDeleted => 'Deleted';
  @override
  String totalVolume(int kg) => '$kg kg';
  @override
  String get addExercise => 'Exercise';
  @override
  String get finishWorkout => 'Finish';
  @override
  String get savedSynced => 'Saved · synced';
  @override
  String get savedSyncFailed => 'Saved · sync failed';
  @override
  String get saved => 'Saved';
  @override
  String get removeExercise => 'Remove';
  @override
  String lastTime(String sets) => 'Last $sets';
  @override
  String best(String kg) => 'PR ${kg}kg';
  @override
  String get addSet => 'Set';
  @override
  String get memoHint => 'Notes';
  @override
  String get addCardio => 'Cardio';
  @override
  String get duration => 'Time';
  @override
  String get distance => 'Distance';
  @override
  String get burned => 'kcal';
  @override
  String get add => 'Add';
  @override
  String get repsUnit => 'reps';
  @override
  String get minUnit => 'min';

  @override
  String get pickExercise => 'Exercises';
  @override
  String get newExercise => 'New';
  @override
  String get search => 'Search';
  @override
  String get all => 'All';
  @override
  String get notFound => 'No results';
  @override
  String get name => 'Name';
  @override
  String get create => 'Create';
  @override
  String get showAgain => 'Show';
  @override
  String get hide => 'Hide';
  @override
  String lastSet(String kg, int reps) => '${kg}kg × $reps';

  @override
  String get body => 'Body';
  @override
  String get logAction => 'Log';
  @override
  String get weight => 'Weight';
  @override
  String get bodyFat => 'Fat %';
  @override
  String get avg7 => '7d avg';
  @override
  String overDays(int n) => '${n}d';
  @override
  String get trend => 'Trend';
  @override
  String get history => 'History';
  @override
  String get noRecords => 'No records';
  @override
  String get save => 'Save';
  @override
  String get chartHint => 'Needs 2+ days';
  @override
  String get d30 => '30d';
  @override
  String get d90 => '90d';
  @override
  String get y1 => '1y';
  @override
  String get syncFailed => 'Sync failed';

  @override
  String get calendar => 'Calendar';
  @override
  String get streak => 'Streak';
  @override
  String get weekStreakShort => 'Weeks';
  @override
  String get monthLabel => 'Month';
  @override
  String get daysUnit => 'd';
  @override
  String get weeksUnit => 'wk';
  @override
  String get timesUnit => '×';
  @override
  String get gym => 'Gym';
  @override
  String get meals => 'Meals';
  @override
  String bodyLine(double w, double? f) =>
      '${w.toStringAsFixed(1)} kg${f == null ? '' : ' · $f%'}';

  @override
  String kcalLeft(int n) => '$n left';
  @override
  String kcalOver(int n) => '$n over';
  @override
  String get ideas => 'Ideas';
  @override
  String get synced => 'Synced';
  @override
  String get sync => 'Sync';
  @override
  String macroLine(int kcal, int p, int f, int c) => '$kcal · P$p F$f C$c';

  @override
  String get custom => 'Custom';
  @override
  String get amount => 'Amount';
  @override
  String get servingsUnit => 'srv';
  @override
  String get servingHint => 'Serving (100g, 1 pc…)';
  @override
  String get saveToList => 'Save to list';
  @override
  String get remove => 'Remove';
  @override
  String oneServing(String s) => '1 srv = $s';
  @override
  String addTo(String slot) => 'Add to $slot';

  @override
  String get settings => 'Settings';
  @override
  String get profile => 'Profile';
  @override
  String get sexLabel => 'Sex';
  @override
  String get birthYear => 'Born';
  @override
  String get height => 'Height';
  @override
  String get goal => 'Goal';
  @override
  String get activity => 'Activity';
  @override
  String get daysPerWeek => 'Days / week';
  @override
  String get targets => 'Targets';
  @override
  String get manual => 'Manual';
  @override
  String get theme => 'Theme';
  @override
  String get font => 'Font';
  @override
  String get fontStandard => 'Standard';
  @override
  String get fontRounded => 'Rounded';
  @override
  String get health => 'Health';
  @override
  String get healthNotSupported => 'iPhone / Android only';
  @override
  String get appleHealth => 'Apple Health';
  @override
  String get healthConnect => 'Health Connect';
  @override
  String get permissionDenied => 'Not allowed';
  @override
  String get foodDisclaimer => 'Food values are estimates.';
  @override
  String get language => 'Language';
}

class LJa extends L {
  const LJa();

  @override
  String get code => 'ja';

  @override
  String dateLong(DateTime d) => DateFormat('M月d日(E)', 'ja').format(d);
  @override
  String dateWithWeekday(DateTime d) => DateFormat('M/d(E)', 'ja').format(d);
  @override
  String monthYear(DateTime d) => DateFormat('yyyy年M月', 'ja').format(d);
  @override
  List<String> get weekdayHeaders => const ['月', '火', '水', '木', '金', '土', '日'];

  @override
  String get navHome => 'ホーム';
  @override
  String get navWorkout => 'トレ';
  @override
  String get navCalendar => 'カレンダー';
  @override
  String get navBody => 'からだ';
  @override
  String get navMeals => 'ごはん';

  @override
  String greeting(int hour) {
    if (hour < 5) return 'こんばんは';
    if (hour < 11) return 'おはよう';
    if (hour < 18) return 'こんにちは';
    return 'こんばんは';
  }

  @override
  String get thisWeekGym => '今週';
  @override
  String perWeek(int goal) => '/$goal';
  @override
  String get weekStreakLabel => '連続';
  @override
  String get thisMonthLabel => '今月';
  @override
  String get allTimeLabel => '累計';
  @override
  String weeks(int n) => '$n週';
  @override
  String times(int n) => '$n回';
  @override
  String get workoutInProgress => 'トレーニング中';
  @override
  String exercisesAndSets(int ex, int sets) => '$ex種目 · $setsセット';
  @override
  String get todayWorkoutDone => '今日は完了';
  @override
  String get startTodayWorkout => 'トレーニング開始';
  @override
  String get todayMeals => 'ごはん';
  @override
  String get p => 'P';
  @override
  String get f => 'F';
  @override
  String get c => 'C';
  @override
  String get protein => 'たんぱく質';
  @override
  String get fat => '脂質';
  @override
  String get carbs => '炭水化物';
  @override
  String get calories => 'kcal';
  @override
  String get logWeight => '体重';
  @override
  String get todayPicks => 'おすすめ';
  @override
  String get nextMealIdeas => 'ごはん案';
  @override
  String get foodListEmpty => '食品なし';
  @override
  String get added => '追加しました';
  @override
  String get start => '開始';
  @override
  String get bodyweight => '自重';
  @override
  String planLine(String weight, int reps, int sets) => '$weight × $reps × $sets';

  @override
  String get workouts => 'トレーニング';
  @override
  String get exerciseList => '種目';
  @override
  String get startNew => '新規';
  @override
  String get continueWorkout => '続き';
  @override
  String get noWorkoutsYet => '記録なし';
  @override
  String get cardio => '有酸素';
  @override
  String setsSummary(int ex, int sets, String vol) => '$ex種目 · $setsセット · $vol';
  @override
  String minutes(int m) => '$m分';

  @override
  String get deleteRecordQ => 'この記録を削除しますか？';
  @override
  String get cancel => 'やめる';
  @override
  String get delete => '削除';
  @override
  String get sessionDeleted => '削除済み';
  @override
  String totalVolume(int kg) => '$kg kg';
  @override
  String get addExercise => '種目';
  @override
  String get finishWorkout => '完了';
  @override
  String get savedSynced => '保存 · 連携済み';
  @override
  String get savedSyncFailed => '保存 · 連携失敗';
  @override
  String get saved => '保存しました';
  @override
  String get removeExercise => '外す';
  @override
  String lastTime(String sets) => '前回 $sets';
  @override
  String best(String kg) => 'PR ${kg}kg';
  @override
  String get addSet => 'セット';
  @override
  String get memoHint => 'メモ';
  @override
  String get addCardio => '有酸素';
  @override
  String get duration => '時間';
  @override
  String get distance => '距離';
  @override
  String get burned => 'kcal';
  @override
  String get add => '追加';
  @override
  String get repsUnit => '回';
  @override
  String get minUnit => '分';

  @override
  String get pickExercise => '種目';
  @override
  String get newExercise => '新規';
  @override
  String get search => '検索';
  @override
  String get all => 'すべて';
  @override
  String get notFound => '見つかりません';
  @override
  String get name => '名前';
  @override
  String get create => '作成';
  @override
  String get showAgain => '表示';
  @override
  String get hide => '非表示';
  @override
  String lastSet(String kg, int reps) => '${kg}kg × $reps';

  @override
  String get body => 'からだ';
  @override
  String get logAction => '記録';
  @override
  String get weight => '体重';
  @override
  String get bodyFat => '体脂肪';
  @override
  String get avg7 => '7日平均';
  @override
  String overDays(int n) => '$n日';
  @override
  String get trend => '推移';
  @override
  String get history => '履歴';
  @override
  String get noRecords => '記録なし';
  @override
  String get save => '保存';
  @override
  String get chartHint => '2日分以上で表示';
  @override
  String get d30 => '30日';
  @override
  String get d90 => '90日';
  @override
  String get y1 => '1年';
  @override
  String get syncFailed => '連携失敗';

  @override
  String get calendar => 'カレンダー';
  @override
  String get streak => '連続';
  @override
  String get weekStreakShort => '週連続';
  @override
  String get monthLabel => '今月';
  @override
  String get daysUnit => '日';
  @override
  String get weeksUnit => '週';
  @override
  String get timesUnit => '回';
  @override
  String get gym => 'ジム';
  @override
  String get meals => 'ごはん';
  @override
  String bodyLine(double w, double? f) =>
      '${w.toStringAsFixed(1)} kg${f == null ? '' : ' · $f%'}';

  @override
  String kcalLeft(int n) => 'あと $n';
  @override
  String kcalOver(int n) => '$n オーバー';
  @override
  String get ideas => 'おすすめ';
  @override
  String get synced => '連携済み';
  @override
  String get sync => '連携';
  @override
  String macroLine(int kcal, int p, int f, int c) => '$kcal · P$p F$f C$c';

  @override
  String get custom => '手入力';
  @override
  String get amount => '量';
  @override
  String get servingsUnit => '食分';
  @override
  String get servingHint => '1食分（100g, 1個…）';
  @override
  String get saveToList => 'リストに保存';
  @override
  String get remove => '削除';
  @override
  String oneServing(String s) => '1食分 = $s';
  @override
  String addTo(String slot) => '$slotに追加';

  @override
  String get settings => '設定';
  @override
  String get profile => 'プロフィール';
  @override
  String get sexLabel => '性別';
  @override
  String get birthYear => '生まれ年';
  @override
  String get height => '身長';
  @override
  String get goal => '目標';
  @override
  String get activity => '活動量';
  @override
  String get daysPerWeek => '週の回数';
  @override
  String get targets => '栄養目標';
  @override
  String get manual => '手動';
  @override
  String get theme => 'テーマ';
  @override
  String get font => 'フォント';
  @override
  String get fontStandard => '標準';
  @override
  String get fontRounded => '丸ゴシック';
  @override
  String get health => 'ヘルスケア';
  @override
  String get healthNotSupported => 'iPhone / Android のみ';
  @override
  String get appleHealth => 'Apple ヘルスケア';
  @override
  String get healthConnect => 'Health Connect';
  @override
  String get permissionDenied => '許可されませんでした';
  @override
  String get foodDisclaimer => '食品の栄養値は目安です。';
  @override
  String get language => '言語';
}

L stringsFor(String code) => code == 'ja' ? const LJa() : const LEn();

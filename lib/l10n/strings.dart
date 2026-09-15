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
  String get sort;
  String get recent;
  String get level;
  String get volume;
  String get summary;
  String get mood;
  String get foodTable;
  String get fromLabel;
  String get productName;
  String get barcodeOptional;
  String get perServing;
  String get gramsEaten;
  String get openFoodFacts;
  String get searchOnline;
  String get lookingUp;
  String get notFoundOnline;
  String get offCredit;
  String get per100g;
  String get foodTableCredit;

  String hi(String name);
  String get todaysProgress;
  String get weeklyActivity;
  String get quickActions;
  String get logFood;
  String get calorieGoal;
  String get seeAll;
  String vsLastWeek(String d);
  String get workoutLabel;
  String get strength;
  String get today;
  String get runTool;
  String get runCompanion;
  String get speed;
  String get pace;
  String get journey;
  String get roulette;
  String get quests;
  String stamps(int n);
  String get lapLength;
  String laps(int n);
  String get spin;
  String nextLandmark(String name, String km);
  String routeTotal(String km);
  String get routeDone;
  String get pause;
  String get resume;
  String get finishRun;
  String get runSaved;
  String newStamps(int n);
  String get questDone;
  String get calendarGoogle;
  String get calendarFile;
  String get resting;
  String kmMark(int n);
  String landmarkReached(String name);
  String get gpsWaiting;
  String get outdoors;
  String callLeft(int s);
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
  String get todayMeals => "Today's meals";
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
  @override
  String get sort => 'Sort';
  @override
  String get recent => 'Recent';
  @override
  String get level => 'Sets';
  @override
  String get volume => 'Volume';

  @override
  String get summary => 'Summary';
  @override
  String get mood => 'Mood';
  @override
  String get foodTable => 'Food table';
  @override
  String get fromLabel => 'From the label';
  @override
  String get productName => 'Product name';
  @override
  String get barcodeOptional => 'Barcode (optional)';
  @override
  String get perServing => 'Per serving';
  @override
  String get gramsEaten => 'Amount eaten (g)';
  @override
  String get openFoodFacts => 'Open Food Facts';
  @override
  String get searchOnline => 'Look up online';
  @override
  String get lookingUp => 'Looking up…';
  @override
  String get notFoundOnline => 'Not found online';
  @override
  String get offCredit => 'Product data from Open Food Facts (ODbL)';
  @override
  String get per100g => 'per 100 g';
  @override
  String get foodTableCredit => 'Source: Standard Tables of Food Composition in Japan, 8th revised edition, 2023 supplement (MEXT)';

  @override
  String hi(String name) => name.isEmpty ? 'Hi there' : 'Hi, $name';
  @override
  String get todaysProgress => "Today's progress";
  @override
  String get weeklyActivity => 'Weekly activity';
  @override
  String get quickActions => 'Quick actions';
  @override
  String get logFood => 'Log food';
  @override
  String get calorieGoal => 'Calorie goal';
  @override
  String get seeAll => 'See all';
  @override
  String vsLastWeek(String d) => '$d vs last week';
  @override
  String get workoutLabel => 'Workout';
  @override
  String get strength => 'Strength';
  @override
  String get today => 'Today';
  @override
  String get runTool => 'Run';
  @override
  String get runCompanion => 'Run with a companion';
  @override
  String get speed => 'Speed';
  @override
  String get pace => 'Pace';
  @override
  String get journey => 'Journey';
  @override
  String get roulette => 'Lap roulette';
  @override
  String get quests => 'Quests';
  @override
  String stamps(int n) => n == 1 ? '1 stamp' : '$n stamps';
  @override
  String get lapLength => 'Lap';
  @override
  String laps(int n) => '$n laps';
  @override
  String get spin => 'Spin';
  @override
  String nextLandmark(String name, String km) => '$name in $km km';
  @override
  String routeTotal(String km) => '$km km on this road';
  @override
  String get routeDone => 'Route complete';
  @override
  String get pause => 'Pause';
  @override
  String get resume => 'Resume';
  @override
  String get finishRun => 'Finish';
  @override
  String get runSaved => "Saved to today's workout";
  @override
  String newStamps(int n) => n == 1 ? '+1 stamp' : '+$n stamps';
  @override
  String get questDone => 'Done';
  @override
  String get calendarGoogle => 'Add to Google Calendar';
  @override
  String get calendarFile => 'Save calendar file (.ics)';
  @override
  String get resting => 'Resting';
  @override
  String kmMark(int n) => '$n km!';
  @override
  String landmarkReached(String name) => 'Reached $name';
  @override
  String get gpsWaiting => 'Waiting for GPS';
  @override
  String get outdoors => 'Outdoors (location)';
  @override
  String callLeft(int s) => '${s}s left';
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
  String get todayMeals => '今日のごはん';
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
  @override
  String get sort => '並び替え';
  @override
  String get recent => '最近';
  @override
  String get level => 'セット';
  @override
  String get volume => '総重量';

  @override
  String get summary => 'サマリー';
  @override
  String get mood => '気分';
  @override
  String get foodTable => '食品成分表';
  @override
  String get fromLabel => '表示から入力';
  @override
  String get productName => '商品名';
  @override
  String get barcodeOptional => 'バーコード（任意）';
  @override
  String get perServing => '1食分';
  @override
  String get gramsEaten => '食べた量（g）';
  @override
  String get openFoodFacts => 'Open Food Facts';
  @override
  String get searchOnline => 'ネットで探す';
  @override
  String get lookingUp => '探しています…';
  @override
  String get notFoundOnline => 'ネットにはありません';
  @override
  String get offCredit => '商品データ：Open Food Facts（ODbL）';
  @override
  String get per100g => '100gあたり';
  @override
  String get foodTableCredit => '出典：日本食品標準成分表（八訂）増補2023年（文部科学省）';

  @override
  String hi(String name) => name.isEmpty ? 'こんにちは' : '$nameさん、こんにちは';
  @override
  String get todaysProgress => '今日の進み';
  @override
  String get weeklyActivity => '今週の活動';
  @override
  String get quickActions => 'クイック操作';
  @override
  String get logFood => 'ごはんを記録';
  @override
  String get calorieGoal => '目標カロリー';
  @override
  String get seeAll => 'すべて';
  @override
  String vsLastWeek(String d) => '先週比 $d';
  @override
  String get workoutLabel => 'トレーニング';
  @override
  String get strength => '筋トレ';
  @override
  String get today => '今日';
  @override
  String get runTool => 'ラン';
  @override
  String get runCompanion => '伴走モードで走る';
  @override
  String get speed => '速度';
  @override
  String get pace => 'ペース';
  @override
  String get journey => '旅';
  @override
  String get roulette => 'ラップルーレット';
  @override
  String get quests => 'お題';
  @override
  String stamps(int n) => 'スタンプ $n 個';
  @override
  String get lapLength => '1周';
  @override
  String laps(int n) => '$n 周';
  @override
  String get spin => '回す';
  @override
  String nextLandmark(String name, String km) => '$name まで $km km';
  @override
  String routeTotal(String km) => 'この道で $km km';
  @override
  String get routeDone => '完走';
  @override
  String get pause => '一時停止';
  @override
  String get resume => '再開';
  @override
  String get finishRun => '終了';
  @override
  String get runSaved => '今日のトレーニングに保存しました';
  @override
  String newStamps(int n) => 'スタンプ +$n';
  @override
  String get questDone => '達成';
  @override
  String get calendarGoogle => 'Google カレンダーに追加';
  @override
  String get calendarFile => 'カレンダーファイル (.ics) を保存';
  @override
  String get resting => '休憩中';
  @override
  String kmMark(int n) => '$n km!';
  @override
  String landmarkReached(String name) => '$name に着いた';
  @override
  String get gpsWaiting => 'GPS を待っています';
  @override
  String get outdoors => '屋外（位置情報）';
  @override
  String callLeft(int s) => 'あと $s 秒';
}

L stringsFor(String code) => code == 'ja' ? const LJa() : const LEn();

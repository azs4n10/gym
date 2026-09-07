# gym

ジムのワークアウト・有酸素・体重・食事を端末内に記録する Flutter アプリ。配色は flipclock と同じ Beige Rose を既定にした、やわらかいパステル調。UI は英語が既定で、設定から日本語に切り替えられる。

## できること

- **トレーニング記録**: 種目 × 重量 × 回数 × セット。前回の記録と自己ベストを見ながら入力。有酸素（種類・時間・距離・消費kcal）も同じセッションに追加できる
- **カレンダー**: ジムに行った日にスタンプ、食事・体重を記録した日にドット。連続日数・週連続達成・今月の回数
- **からだ**: 体重・体脂肪率の記録と 30日/90日/1年 の推移グラフ、7日平均
- **ごはん**: 朝・昼・夜・間食ごとにカロリーと PFC を記録。目標は身長・体重・年齢・活動量から Mifflin-St Jeor 式で算出（手動上書き可）
- **おすすめ**: 最近鍛えていない部位と、前回の実績に応じた重量・回数の提案（全セット10回達成なら +2.5kg、脚は +5kg）。食事は残りの PFC に合う食品を提案
- **ヘルスケア連携**: iOS は Apple ヘルスケア、Android は Health Connect に、トレーニング・体重・食事を書き込む（`health` パッケージ）。Web では無効
- **きせかえ**: flipclock 由来の 9 スキン（Beige Rose / Yumekawa / Lavender / Mint Peach / Sugar Pink / Night Star / Midnight Plum / Cocoa Night / Charcoal Rose）

## 構成

```
lib/
  main.dart              起動・Provider 配線・幅広画面では 480px にセンタリング
  l10n/strings.dart      UI 文言（en / ja）
  theme/                 Skin 定義と ThemeData
  models/                enum 群と UserProfile（shared_preferences）
  data/database.dart     drift のテーブル定義（sqlite）
  data/seed/             種目・食品の初期データ（英語名 + 日本語表示用の対応表）
  state/                 WorkoutState / BodyState / MealState / AppState
  services/              栄養計算・連続記録・提案ロジック・ヘルスケア連携
  screens/               ホーム / トレ / カレンダー / からだ / ごはん / 設定
  widgets/               カード・リング・ステッパー入力
```

## 開発

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # スキーマ変更時のみ
flutter run -d chrome
flutter test
```

Web では `web/sqlite3.wasm` と `web/drift_worker.js` を使って sqlite を動かす（drift 公式リリースから取得したもの）。

## iPhone / iPad で使う（GitHub Pages）

ネイティブアプリではなく Web アプリとして公開し、Safari の「ホーム画面に追加」で使う。縦横どちらの向きにも対応していて、横向きのときはタブが左のレールに移る。

1. このフォルダを単独のリポジトリにして GitHub に push する（リポジトリ名は何でもよい。`--base-href` はワークフローがリポジトリ名から自動で決める）
   ```
   git init && git add -A && git commit -m "Initial commit"
   gh repo create gym --private --source=. --push
   ```
2. GitHub のリポジトリ設定 → Pages → Source を「GitHub Actions」にする
3. `main` に push するたびに `.github/workflows/deploy.yml` がテスト・ビルド・デプロイまで行う。URL は `https://<ユーザー名>.github.io/<リポジトリ名>/`
4. iPhone / iPad の Safari でその URL を開き、共有メニューから「ホーム画面に追加」

データは端末のブラウザ内（IndexedDB）に保存される。Safari のサイトデータを消すと記録も消えるので注意。

## 注意

- 食品リストの栄養値は 1 食分の目安。パッケージ表示がある場合はそちらを優先して自分で入力したものに置き換える前提
- Android のヘルスケア連携は Health Connect アプリが必要。`minSdk 26`、`FlutterFragmentActivity`、Manifest の権限は設定済み
- iOS は HealthKit の Capability を Xcode 側で有効にする必要がある（Info.plist の説明文は追加済み）。Windows では iOS ビルド不可

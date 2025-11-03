# Firebase Emulator統合テストガイド

**Feature**: 002-task-management  
**Test Type**: Integration Tests with Firebase Emulator  
**Purpose**: FirestoreリポジトリのE2Eテスト実行

---

## 概要

このディレクトリには、Firebase Emulatorを使用したリポジトリの統合テストが含まれています。

### テストファイル

- `project_repository_integration_test.dart` - プロジェクトリポジトリの統合テスト
- `task_repository_integration_test.dart` - タスクリポジトリの統合テスト

---

## 前提条件

### 1. Firebase Emulatorのインストール

```bash
# Firebase CLIがインストールされていない場合
npm install -g firebase-tools

# Firebase Emulatorコンポーネントのインストール
firebase init emulators
```

### 2. Flutter環境

```bash
fvm flutter --version  # 3.35.7以上
fvm dart --version     # 3.9.2以上
```

---

## テスト実行手順

### Step 1: Firebase Emulatorの起動

**ターミナル1** (Emulator実行用):

```bash
cd firebase
firebase emulators:start
```

Emulatorが起動すると、以下のようなメッセージが表示されます:

```
┌─────────────────────────────────────────────────────────────┐
│ ✔  All emulators ready! It is now safe to connect your app. │
│ i  View Emulator UI at http://127.0.0.1:4000/               │
└─────────────────────────────────────────────────────────────┘

┌────────────────┬────────────────┬─────────────────────────────────┐
│ Emulator       │ Host:Port      │ View in Emulator UI             │
├────────────────┼────────────────┼─────────────────────────────────┤
│ Firestore      │ 0.0.0.0:8080   │ http://127.0.0.1:4000/firestore │
└────────────────┴────────────────┴─────────────────────────────────┘
```

### Step 2: 統合テストの実行

**ターミナル2** (テスト実行用):

```bash
cd flutter_app

# すべての統合テストを実行
fvm flutter test integration_test/

# 特定のテストファイルのみ実行
fvm flutter test integration_test/project_repository_integration_test.dart
fvm flutter test integration_test/task_repository_integration_test.dart
```

### Step 3: テスト結果の確認

テストが成功すると、以下のような出力が表示されます:

```
00:05 +67: All tests passed!
```

---

## テストカバレッジ

### Project Repository Tests (67 tests)

#### createProject (6 tests)
- ✅ 正常にプロジェクトを作成できること
- ✅ 説明なしでプロジェクトを作成できること
- ✅ プロジェクト名が空の場合はValidationExceptionをスローすること
- ✅ プロジェクト名が100文字を超える場合はValidationExceptionをスローすること
- ✅ 説明が500文字を超える場合はValidationExceptionをスローすること
- ✅ プロジェクト名の前後の空白がトリミングされること

#### watchUserProjects (4 tests)
- ✅ ユーザーのプロジェクト一覧をリアルタイムで取得できること
- ✅ 複数プロジェクトが作成日時降順でソートされること
- ✅ 他のユーザーのプロジェクトは取得されないこと
- ✅ limitパラメータで取得件数を制限できること

#### watchProject (3 tests)
- ✅ プロジェクトIDで単一プロジェクトを取得できること
- ✅ 存在しないプロジェクトIDの場合nullを返すこと
- ✅ プロジェクトが更新されたらStreamが更新されること

#### updateProject (5 tests)
- ✅ プロジェクト名を更新できること
- ✅ 説明を更新できること
- ✅ 名前と説明を同時に更新できること
- ✅ 存在しないプロジェクトの更新時はNotFoundExceptionをスローすること
- ✅ 無効な名前での更新時はValidationExceptionをスローすること

#### deleteProject (3 tests)
- ✅ プロジェクトを削除できること
- ✅ プロジェクト削除時に関連タスクもカスケード削除されること
- ✅ 存在しないプロジェクトの削除時はNotFoundExceptionをスローすること

#### exists (2 tests)
- ✅ 存在するプロジェクトの場合trueを返すこと
- ✅ 存在しないプロジェクトの場合falseを返すこと

#### Concurrent Operations (2 tests)
- ✅ 複数のプロジェクト作成を並行実行できること
- ✅ Last Write Wins戦略で衝突が解決されること

### Task Repository Tests (50+ tests)

#### createTask (5 tests)
- ✅ 正常にタスクを作成できること
- ✅ 説明と期限なしでタスクを作成できること
- ✅ タスク名が空の場合はValidationExceptionをスローすること
- ✅ タスク名が200文字を超える場合はValidationExceptionをスローすること
- ✅ 説明が1000文字を超える場合はValidationExceptionをスローすること

#### watchProjectTasks (7 tests)
- ✅ プロジェクトのタスク一覧をリアルタイムで取得できること
- ✅ 作成日時降順でソートされること（デフォルト）
- ✅ 期限日時昇順でソートできること
- ✅ 完了済みタスクのみフィルターできること
- ✅ 未完了タスクのみフィルターできること
- ✅ limitパラメータで取得件数を制限できること

#### watchTask (2 tests)
- ✅ タスクIDで単一タスクを取得できること
- ✅ 存在しないタスクIDの場合nullを返すこと

#### updateTask (4 tests)
- ✅ タスク名を更新できること
- ✅ 説明を更新できること
- ✅ 期限を更新できること
- ✅ 存在しないタスクの更新時はNotFoundExceptionをスローすること

#### toggleTaskCompletion (3 tests)
- ✅ タスクを完了状態に変更できること
- ✅ タスクを未完了状態に戻せること
- ✅ 存在しないタスクの完了切り替え時はNotFoundExceptionをスローすること

#### deleteTask (2 tests)
- ✅ タスクを削除できること
- ✅ 存在しないタスクの削除時はNotFoundExceptionをスローすること

#### getProjectTaskStatistics (3 tests)
- ✅ タスク統計を正しく計算できること
- ✅ 全タスク完了時isProjectCompletedがtrueになること
- ✅ タスクがない場合は0%を返すこと

#### exists (2 tests)
- ✅ 存在するタスクの場合trueを返すこと
- ✅ 存在しないタスクの場合falseを返すこと

#### Complex Scenarios (3 tests)
- ✅ 無限スクロールシナリオ: ページネーションが正しく動作すること
- ✅ ソート+フィルターの複合シナリオ
- ✅ 並行操作シナリオ: 複数のタスク作成を並行実行できること

---

## テストシナリオ詳細

### 1. CRUD操作の基本テスト

すべてのリポジトリメソッド（Create, Read, Update, Delete）が正しく動作することを検証します。

### 2. リアルタイム更新テスト

Firestore Streamが変更を正しく検知し、UIに反映されることを検証します。

### 3. バリデーションテスト

不正な入力値（空文字、文字数制限超過等）に対して適切な例外がスローされることを検証します。

### 4. ページネーションテスト

無限スクロール機能で使用されるカーソルベースのページネーションが正しく動作することを検証します。

### 5. ソート・フィルターテスト

タスクの並び替え（作成日時・期限）とフィルター（完了・未完了）が正しく機能することを検証します。

### 6. カスケード削除テスト

プロジェクト削除時に関連タスクも自動削除されることを検証します。

### 7. 並行操作テスト

複数の操作を並行実行した際に、データの整合性が保たれることを検証します。

### 8. 衝突解決テスト

Last Write Wins戦略により、同時編集の競合が適切に処理されることを検証します。

---

## トラブルシューティング

### 問題1: Firebase Emulatorが起動しない

**症状**:
```
Error: Could not start Firestore Emulator, port taken.
```

**解決策**:
```bash
# ポート8080を使用しているプロセスを確認
lsof -i :8080

# プロセスを終了
kill -9 <PID>

# Emulatorを再起動
firebase emulators:start
```

### 問題2: テストがEmulatorに接続できない

**症状**:
```
[cloud_firestore/unavailable] The service is currently unavailable.
```

**解決策**:
1. Firebase Emulatorが起動していることを確認
2. `http://127.0.0.1:4000/` でEmulator UIにアクセスできるか確認
3. テストファイル内の接続設定を確認:
   ```dart
   FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
   ```

### 問題3: テストデータがクリーンアップされない

**症状**: 前回のテストデータが残っている

**解決策**:
```bash
# Emulatorを停止してデータをクリア
firebase emulators:start --import=./emulator-data --export-on-exit

# または、Emulator UIから手動でデータをクリア
# http://127.0.0.1:4000/firestore
```

### 問題4: テストが途中で止まる

**症状**: テストが無限に待機する

**解決策**:
1. `tearDown()`でデータクリーンアップが正しく実行されているか確認
2. タイムアウトを追加:
   ```dart
   test('...', () async {
     // ...
   }).timeout(const Duration(seconds: 30));
   ```

---

## CI/CD統合

### GitHub Actions例

```yaml
name: Integration Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  integration-tests:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.7'
          channel: 'stable'
      
      - name: Install Firebase CLI
        run: npm install -g firebase-tools
      
      - name: Start Firebase Emulators
        run: |
          cd firebase
          firebase emulators:start --project test-project &
          sleep 10
      
      - name: Run Integration Tests
        run: |
          cd flutter_app
          flutter test integration_test/
      
      - name: Stop Firebase Emulators
        if: always()
        run: |
          pkill -f "firebase emulators"
```

---

## ベストプラクティス

### 1. テストデータの管理

```dart
// テストごとに独立したデータを使用
const testUserId = 'test-user-123';
const testProjectId = 'test-project-${DateTime.now().millisecondsSinceEpoch}';
```

### 2. クリーンアップの徹底

```dart
tearDown(() async {
  // 各テスト後に必ずデータをクリーンアップ
  final snapshot = await FirebaseFirestore.instance
      .collection('tasks')
      .where('userId', isEqualTo: testUserId)
      .get();
  
  for (final doc in snapshot.docs) {
    await doc.reference.delete();
  }
});
```

### 3. タイムアウトの設定

```dart
test('長時間実行テスト', () async {
  // ...
}, timeout: const Duration(seconds: 60));
```

### 4. 非同期待機

```dart
// Streamが更新されるまで待機
await Future.delayed(const Duration(milliseconds: 500));
```

---

## まとめ

これらの統合テストにより、以下が保証されます:

- ✅ FirestoreリポジトリのCRUD操作が正しく動作
- ✅ リアルタイム更新機能が正常に機能
- ✅ バリデーションが適切に実行
- ✅ ページネーション・ソート・フィルターが正確
- ✅ カスケード削除が正しく実装
- ✅ 並行操作での整合性維持
- ✅ Last Write Wins戦略の衝突解決

本番環境へのデプロイ前に、すべての統合テストがパスすることを確認してください。

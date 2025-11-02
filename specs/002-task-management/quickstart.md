# Quickstart Guide: Project and Task Management

**Feature**: 002-task-management  
**Target Audience**: Developers implementing this feature  
**Estimated Reading Time**: 15 minutes

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Architecture](#architecture)
4. [Setup Instructions](#setup-instructions)
5. [Key Patterns](#key-patterns)
6. [Implementation Checklist](#implementation-checklist)
7. [Testing Guide](#testing-guide)
8. [Troubleshooting](#troubleshooting)

---

## Overview

このガイドでは、**002-task-management**機能（プロジェクトとタスク管理）の実装方法を説明します。この機能により、ユーザーはプロジェクトを作成し、各プロジェクト内でタスクを管理できます。

### 主要機能

- ✅ プロジェクトCRUD（作成・読取・更新・削除）
- ✅ タスクCRUD（作成・読取・更新・削除・完了/未完了切り替え）
- ✅ 無限スクロール対応（30件/ページ）
- ✅ プロジェクト進捗表示（完了率・期限超過タスク数）
- ✅ プロジェクト100%完了時のお祝いメッセージ
- ✅ オフラインサポート（Last Write Wins戦略）
- ✅ AI賞賛機能との連携（非同期・非ブロッキング）

### 技術スタック

| 技術 | バージョン | 用途 |
|-----|-----------|------|
| Dart | 3.9.2+ | プログラミング言語 |
| Flutter | 3.35.7+ | UIフレームワーク |
| Riverpod | 2.6.1 | 状態管理 |
| Cloud Firestore | latest | データベース |
| Freezed | latest | Immutableモデル生成 |

---

## Prerequisites

### 必須の事前知識

- Dart言語基礎（非同期処理、Stream）
- Flutter基本（Widget、State、Navigation）
- Riverpodの基本概念（Provider、StateNotifier）
- Cloud Firestoreの基本操作（コレクション、ドキュメント、クエリ）

### 必須の開発環境

```bash
# Flutter/Dartバージョン確認
fvm flutter --version  # 3.35.7以上
fvm dart --version     # 3.9.2以上

# Firebase CLIインストール済み
firebase --version     # 13.x以上

# Firebase Emulator起動済み
firebase emulators:start
```

### 依存関係の追加

`flutter_app/pubspec.yaml`に以下を追加:

```yaml
dependencies:
  # 状態管理
  flutter_riverpod: ^2.6.1
  
  # Firebase
  cloud_firestore: ^5.7.0
  firebase_core: ^3.13.1
  
  # Immutableモデル
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

dev_dependencies:
  # コード生成
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  
  # テスト
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
```

インストール実行:

```bash
cd flutter_app
fvm flutter pub get
```

---

## Architecture

### ディレクトリ構造

```
lib/
├── core/
│   ├── exceptions/
│   │   ├── validation_exception.dart
│   │   ├── not_found_exception.dart
│   │   └── unauthorized_exception.dart
│   └── providers/
│       └── firebase_providers.dart
├── features/
│   └── task_management/
│       ├── data/
│       │   ├── models/
│       │   │   ├── project.dart (Freezed model)
│       │   │   ├── task.dart (Freezed model)
│       │   │   └── task_statistics.dart (Freezed model)
│       │   └── repositories/
│       │       ├── i_project_repository.dart (interface)
│       │       ├── firestore_project_repository.dart (impl)
│       │       ├── i_task_repository.dart (interface)
│       │       └── firestore_task_repository.dart (impl)
│       ├── domain/
│       │   └── enums/
│       │       └── task_sort_by.dart
│       ├── presentation/
│       │   ├── controllers/
│       │   │   ├── project_list_controller.dart
│       │   │   ├── task_list_controller.dart
│       │   │   └── project_detail_controller.dart
│       │   ├── screens/
│       │   │   ├── project_list_screen.dart
│       │   │   ├── project_detail_screen.dart
│       │   │   └── task_edit_screen.dart
│       │   └── widgets/
│       │       ├── project_card.dart
│       │       ├── task_tile.dart
│       │       ├── progress_indicator_widget.dart
│       │       └── completion_celebration_dialog.dart
│       └── providers/
│           ├── repository_providers.dart
│           ├── project_providers.dart
│           └── task_providers.dart
└── shared/
    └── widgets/
        └── error_boundary.dart
```

### レイヤー構成

```
┌─────────────────────────────────────┐
│   Presentation Layer (UI)           │
│   - Screens, Widgets, Controllers   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Domain Layer (Business Logic)     │
│   - Repository Interfaces, Enums    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Data Layer (Infrastructure)       │
│   - Firestore Repositories, Models  │
└─────────────────────────────────────┘
```

---

## Setup Instructions

### Step 1: Firestoreセキュリティルール設定

`firebase/firestore.rules`に以下を追加:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Projects Collection
    match /projects/{projectId} {
      allow read: if request.auth != null 
          && resource.data.userId == request.auth.uid;
      
      allow create: if request.auth != null 
          && request.resource.data.userId == request.auth.uid
          && request.resource.data.name is string
          && request.resource.data.name.size() >= 1
          && request.resource.data.name.size() <= 100;
      
      allow update: if request.auth != null 
          && resource.data.userId == request.auth.uid
          && request.resource.data.userId == resource.data.userId;
      
      allow delete: if request.auth != null 
          && resource.data.userId == request.auth.uid;
    }
    
    // Tasks Collection
    match /tasks/{taskId} {
      allow read: if request.auth != null 
          && resource.data.userId == request.auth.uid;
      
      allow create: if request.auth != null 
          && request.resource.data.userId == request.auth.uid
          && request.resource.data.name is string
          && request.resource.data.name.size() >= 1
          && request.resource.data.name.size() <= 200;
      
      allow update: if request.auth != null 
          && resource.data.userId == request.auth.uid
          && request.resource.data.projectId == resource.data.projectId
          && request.resource.data.userId == resource.data.userId;
      
      allow delete: if request.auth != null 
          && resource.data.userId == request.auth.uid;
    }
  }
}
```

デプロイ:

```bash
cd firebase
firebase deploy --only firestore:rules
```

### Step 2: Firestoreインデックス設定

`firebase/firestore.indexes.json`に以下を追加:

```json
{
  "indexes": [
    {
      "collectionGroup": "projects",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "tasks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "projectId", "order": "ASCENDING" },
        { "fieldPath": "isCompleted", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "tasks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "projectId", "order": "ASCENDING" },
        { "fieldPath": "isCompleted", "order": "ASCENDING" },
        { "fieldPath": "dueDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "tasks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

デプロイ:

```bash
firebase deploy --only firestore:indexes
```

### Step 3: Freezedモデル生成

```bash
cd flutter_app
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

生成されるファイル:
- `project.freezed.dart`
- `project.g.dart`
- `task.freezed.dart`
- `task.g.dart`
- `task_statistics.freezed.dart`
- `task_statistics.g.dart`

### Step 4: Provider設定

`lib/features/task_management/providers/repository_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/i_project_repository.dart';
import '../data/repositories/firestore_project_repository.dart';
import '../data/repositories/i_task_repository.dart';
import '../data/repositories/firestore_task_repository.dart';

final projectRepositoryProvider = Provider<IProjectRepository>((ref) {
  return FirestoreProjectRepository();
});

final taskRepositoryProvider = Provider<ITaskRepository>((ref) {
  return FirestoreTaskRepository();
});
```

---

## Key Patterns

### 1. Repository Pattern（リポジトリパターン）

**目的**: データアクセスロジックをビジネスロジックから分離

```dart
// インターフェース定義
abstract class IProjectRepository {
  Stream<List<Project>> watchUserProjects({required String userId});
  Future<Project> createProject({required String userId, required String name});
}

// Firestore実装
class FirestoreProjectRepository implements IProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Stream<List<Project>> watchUserProjects({required String userId}) {
    return _firestore
        .collection('projects')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList());
  }
}

// Fake実装（テスト用）
class FakeProjectRepository implements IProjectRepository {
  final Map<String, Project> _projects = {};
  
  @override
  Stream<List<Project>> watchUserProjects({required String userId}) {
    return Stream.value(_projects.values.where((p) => p.userId == userId).toList());
  }
}
```

### 2. Stream-based UI（ストリームベースUI）

**目的**: リアルタイムデータ更新の自動反映

```dart
// Provider定義
final userProjectsProvider = StreamProvider.family<List<Project>, String>(
  (ref, userId) {
    final repository = ref.watch(projectRepositoryProvider);
    return repository.watchUserProjects(userId: userId);
  },
);

// UI側での使用
class ProjectListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final projectsAsync = ref.watch(userProjectsProvider(currentUser!.uid));
    
    return projectsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
      data: (projects) => ListView.builder(
        itemCount: projects.length,
        itemBuilder: (context, index) => ProjectCard(project: projects[index]),
      ),
    );
  }
}
```

### 3. Optimistic Updates（楽観的更新）

**目的**: UIの即座反応とオフライン対応

```dart
Future<void> toggleTaskCompletion(Task task) async {
  // 1. UIに即座反映（楽観的更新）
  state = AsyncValue.data(
    state.value!.map((t) => t.id == task.id 
        ? t.copyWith(isCompleted: !t.isCompleted) 
        : t
    ).toList(),
  );
  
  try {
    // 2. バックエンド更新
    await _repository.toggleTaskCompletion(
      taskId: task.id,
      isCompleted: !task.isCompleted,
    );
  } catch (e) {
    // 3. エラー時はロールバック
    state = AsyncValue.data(
      state.value!.map((t) => t.id == task.id ? task : t).toList(),
    );
    rethrow;
  }
}
```

### 4. Infinite Scroll（無限スクロール）

**目的**: 大量データの効率的表示

```dart
class TaskListController extends StateNotifier<AsyncValue<List<Task>>> {
  static const int _pageSize = 30;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  
  Future<void> loadMore() async {
    if (!_hasMore) return;
    
    final currentTasks = state.value ?? [];
    final moreTasks = await _repository.watchProjectTasks(
      projectId: _projectId,
      limit: _pageSize,
      startAfterDoc: _lastDocument,
    ).first;
    
    if (moreTasks.length < _pageSize) {
      _hasMore = false;
    }
    
    state = AsyncValue.data([...currentTasks, ...moreTasks]);
  }
}

// UI側での使用
ListView.builder(
  controller: _scrollController,
  itemCount: tasks.length + (_hasMore ? 1 : 0),
  itemBuilder: (context, index) {
    if (index == tasks.length) {
      // ローディングインジケータ
      _loadMore();
      return const CircularProgressIndicator();
    }
    return TaskTile(task: tasks[index]);
  },
);
```

### 5. Error Boundary（エラー境界）

**目的**: エラー伝播の制御とユーザーフレンドリーなエラー表示

```dart
class ErrorBoundary extends ConsumerWidget {
  final Widget child;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorWidget.withErrorHandling(
      child: child,
      onError: (error, stackTrace) {
        // ログ記録
        print('Error: $error');
        
        // ユーザーに通知
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getErrorMessage(error))),
        );
      },
    );
  }
  
  String _getErrorMessage(Object error) {
    if (error is ValidationException) return error.message;
    if (error is NotFoundException) return 'データが見つかりません';
    if (error is FirebaseException) return 'ネットワークエラーが発生しました';
    return '予期しないエラーが発生しました';
  }
}
```

---

## Implementation Checklist

### Phase 1: データ層実装

- [ ] `project.dart` モデル作成（Freezed）
- [ ] `task.dart` モデル作成（Freezed）
- [ ] `task_statistics.dart` モデル作成（Freezed）
- [ ] `i_project_repository.dart` インターフェース作成
- [ ] `firestore_project_repository.dart` 実装
- [ ] `fake_project_repository.dart` テスト用実装
- [ ] `i_task_repository.dart` インターフェース作成
- [ ] `firestore_task_repository.dart` 実装
- [ ] `fake_task_repository.dart` テスト用実装
- [ ] Freezed生成実行（`build_runner`）

### Phase 2: ドメイン層実装

- [ ] `task_sort_by.dart` Enum作成
- [ ] `validation_exception.dart` 作成
- [ ] `not_found_exception.dart` 作成
- [ ] `unauthorized_exception.dart` 作成

### Phase 3: Providerセットアップ

- [ ] `repository_providers.dart` 作成
- [ ] `project_providers.dart` 作成（StreamProvider）
- [ ] `task_providers.dart` 作成（StreamProvider）

### Phase 4: プレゼンテーション層実装

- [ ] `project_list_screen.dart` 作成
- [ ] `project_detail_screen.dart` 作成
- [ ] `task_edit_screen.dart` 作成
- [ ] `project_card.dart` ウィジェット作成
- [ ] `task_tile.dart` ウィジェット作成
- [ ] `progress_indicator_widget.dart` 作成
- [ ] `completion_celebration_dialog.dart` 作成
- [ ] `project_list_controller.dart` 作成
- [ ] `task_list_controller.dart` 作成（無限スクロール対応）
- [ ] `project_detail_controller.dart` 作成

### Phase 5: Firebase設定

- [ ] Firestoreセキュリティルール更新・デプロイ
- [ ] Firestoreインデックス設定・デプロイ
- [ ] Firebase Emulatorでテスト確認

### Phase 6: テスト実装

- [ ] Projectリポジトリ単体テスト
- [ ] Taskリポジトリ単体テスト
- [ ] Controllerユニットテスト
- [ ] Firebase Emulator統合テスト
- [ ] UIウィジェットテスト

---

## Testing Guide

### 1. Unit Tests（単体テスト）

```bash
# 全テスト実行
fvm flutter test

# 特定ファイルのみ
fvm flutter test test/features/task_management/data/repositories/firestore_project_repository_test.dart

# カバレッジ付き
fvm flutter test --coverage
```

### 2. Integration Tests（統合テスト）

```bash
# Firebase Emulator起動
cd firebase
firebase emulators:start

# 別ターミナルで統合テスト実行
cd flutter_app
fvm flutter test integration_test/
```

### 3. Widget Tests（ウィジェットテスト）

```bash
fvm flutter test test/features/task_management/presentation/widgets/
```

### 4. Manual Testing Checklist

- [ ] プロジェクト作成（名前のみ）
- [ ] プロジェクト作成（説明付き）
- [ ] プロジェクト編集
- [ ] プロジェクト削除（関連タスクも削除されるか確認）
- [ ] タスク作成（期限なし）
- [ ] タスク作成（期限あり）
- [ ] タスク完了チェック（completedAt設定確認）
- [ ] タスク未完了に戻す（completedAt削除確認）
- [ ] 30件以上のタスク作成→無限スクロール確認
- [ ] プロジェクト100%完了→お祝いダイアログ表示確認
- [ ] オフライン操作→オンライン復帰時の同期確認

---

## Troubleshooting

### 問題1: Firestoreインデックスエラー

**症状**:
```
[cloud_firestore/failed-precondition] The query requires an index.
```

**解決策**:
1. エラーメッセージ内のリンクをクリック
2. Firebase Consoleで自動生成されたインデックス作成リンクを開く
3. インデックス作成完了まで待機（数分）
4. または`firestore.indexes.json`を手動更新して`firebase deploy --only firestore:indexes`

### 問題2: セキュリティルール違反

**症状**:
```
[cloud_firestore/permission-denied] Missing or insufficient permissions.
```

**解決策**:
1. Firebase Consoleで「ルール」タブを開く
2. ログを確認し、どのルールで拒否されたか確認
3. `firestore.rules`を修正
4. `firebase deploy --only firestore:rules`で再デプロイ

### 問題3: Freezed生成エラー

**症状**:
```
[ERROR] Missing "part 'project.freezed.dart';"
```

**解決策**:
```dart
// project.dartの先頭に追加
part 'project.freezed.dart';
part 'project.g.dart';

// 再生成実行
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

### 問題4: 無限スクロールが動作しない

**症状**: スクロール時に次のページが読み込まれない

**解決策**:
1. `ListView.builder`に`ScrollController`を設定確認
2. `_scrollController.addListener()`で閾値判定を追加
3. `_hasMore`フラグが正しく更新されているか確認
4. Firestoreクエリの`startAfterDocument`が正しく渡されているか確認

### 問題5: オフライン同期が失敗する

**症状**: オフライン時の操作がオンライン復帰後も反映されない

**解決策**:
```dart
// Firestoreのオフライン永続化を有効化
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

---

## Next Steps

1. **データ層から実装開始**: `project.dart`, `task.dart`モデル作成
2. **リポジトリ実装**: `firestore_project_repository.dart`実装
3. **Provider設定**: Riverpod Providerを定義
4. **UI実装**: `project_list_screen.dart`から作成
5. **テスト実装**: ユニットテスト→統合テスト→UIテストの順
6. **本番デプロイ**: Firebase Emulatorでテスト完了後、本番環境へデプロイ

---

## Useful Commands Reference

```bash
# Firebase Emulator起動
cd firebase && firebase emulators:start

# Freezed/json_serializableコード生成
cd flutter_app && fvm flutter pub run build_runner build --delete-conflicting-outputs

# Firestoreルール/インデックスデプロイ
cd firebase && firebase deploy --only firestore

# テスト実行（カバレッジ付き）
cd flutter_app && fvm flutter test --coverage

# アプリ起動（Firebase Emulator接続）
cd flutter_app && fvm flutter run

# 依存関係更新
cd flutter_app && fvm flutter pub upgrade
```

---

## Summary

このクイックスタートガイドでは、以下の内容をカバーしました：

✅ プロジェクト・タスク管理機能の全体像  
✅ 必要な技術スタックと開発環境  
✅ アーキテクチャとディレクトリ構造  
✅ Firebase設定手順（セキュリティルール・インデックス）  
✅ 重要な実装パターン5つ  
✅ 実装チェックリスト（Phase 1-6）  
✅ テスト戦略とトラブルシューティング

これで実装を開始する準備が整いました！各フェーズのチェックリストに従って進めてください。

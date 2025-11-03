# Research: Project and Task Management

**Feature**: 002-task-management  
**Date**: 2025-11-03  
**Status**: Completed

## Overview

このドキュメントはタスク管理機能の実装に必要な技術調査結果をまとめたものです。Technical Contextで特定された「NEEDS CLARIFICATION」項目を解決します。

---

## Research Topics

### 1. 無限スクロール実装のベストプラクティス

**Decision**: `ListView.builder` + Firestore Query Pagination + `ScrollController`

**Rationale**:
- Flutter標準の`ListView.builder`は遅延レンダリングをサポートし、大量アイテムでもメモリ効率的
- Firestoreの`startAfterDocument`を使用したカーソルベースページネーションが推奨パターン
- `ScrollController`で80%スクロール時に次ページをトリガー
- 既にロード済みのアイテムはキャッシュし、重複読み取りを防止

**Implementation Pattern**:
```dart
class TaskListController extends StateNotifier<AsyncValue<List<Task>>> {
  static const _pageSize = 30;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  Future<void> loadMore() async {
    if (!_hasMore) return;
    
    Query query = FirebaseFirestore.instance
        .collection('tasks')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);
    
    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }
    
    final snapshot = await query.get();
    _lastDocument = snapshot.docs.lastOrNull;
    _hasMore = snapshot.docs.length == _pageSize;
    
    // Append to existing list
  }
}
```

**Alternatives Considered**:
- **Pagination with page numbers**: Firestoreはオフセットベースページネーションに非効率（スキップされたドキュメントも読み取りコストが発生）
- **Load all at once**: 1000タスク以上で致命的なパフォーマンス低下、メモリ不足のリスク
- **Third-party infinite scroll package**: 追加依存を避け、Flutter標準APIで十分実装可能

**References**:
- [Paginate data with query cursors - Firebase](https://firebase.google.com/docs/firestore/query-data/query-cursors)
- [ListView.builder - Flutter API](https://api.flutter.dev/flutter/widgets/ListView/ListView.builder.html)

---

### 2. Firestoreクエリカーソルの効率的な管理方法

**Decision**: Riverpod `StateNotifier` + Immutable State で管理

**Rationale**:
- カーソル（`DocumentSnapshot`）を状態として保持し、ページロード間で共有
- Riverpodの状態管理により、ウィジェット再ビルド時もカーソルが維持される
- Immutableな状態設計により、意図しないカーソル変更を防止
- メモリリークを避けるため、プロジェクト切り替え時は状態をリセット

**Implementation Pattern**:
```dart
@freezed
class TaskListState with _$TaskListState {
  const factory TaskListState({
    required List<Task> tasks,
    DocumentSnapshot? lastDocument,
    @Default(true) bool hasMore,
    @Default(false) bool isLoading,
  }) = _TaskListState;
}

final taskListProvider = StateNotifierProvider.family<TaskListController, TaskListState, String>(
  (ref, projectId) => TaskListController(projectId),
);
```

**Best Practices**:
- カーソルは`lastDocument`として保存（次のクエリで`startAfterDocument`に使用）
- `hasMore`フラグで無限ループを防止（読み込み完了判定）
- `isLoading`フラグでUI状態管理（ローディングインジケーター表示）
- プロジェクト切り替え時は`ref.invalidate(taskListProvider)`で状態リセット

**Alternatives Considered**:
- **Global variable**: 状態管理が不適切、テスト困難
- **StatefulWidget内で管理**: 画面遷移時に状態が失われる、複数箇所で共有不可
- **Redux/Bloc**: Riverpodより冗長、このユースケースには過剰

**References**:
- [Riverpod StateNotifier - Official Docs](https://riverpod.dev/docs/concepts/providers/#statenotifierprovider)
- [Freezed - Immutable State](https://pub.dev/packages/freezed)

---

### 3. Firestoreモック戦略

**Decision**: Firebase Emulator for Integration Tests + Fake Repository for Unit Tests

**Rationale**:
- **Integration Tests**: Firebase Emulatorを使用し、実際のFirestore APIと同じ動作を検証
  - Firestoreのクエリ、インデックス、セキュリティルールを正確にテスト可能
  - CI/CDパイプラインでも自動実行可能
- **Unit Tests**: Fake Repositoryパターンでビジネスロジックのみをテスト
  - Firestoreへの依存を排除し、高速なテスト実行
  - モックデータで様々なエッジケースをテスト

**Implementation Pattern**:

```dart
// Abstract Repository
abstract class TaskRepository {
  Future<List<Task>> getTasksByProject(String projectId);
  Future<void> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String taskId);
}

// Production Implementation
class FirestoreTaskRepository implements TaskRepository {
  final FirebaseFirestore _firestore;
  // Real Firestore operations
}

// Test Implementation
class FakeTaskRepository implements TaskRepository {
  final Map<String, Task> _tasks = {};
  
  @override
  Future<List<Task>> getTasksByProject(String projectId) async {
    return _tasks.values
        .where((task) => task.projectId == projectId)
        .toList();
  }
  // In-memory operations for testing
}
```

**Integration Test Setup**:
```bash
# Start Firebase Emulator
firebase emulators:start --only firestore

# Run integration tests
flutter test integration_test/
```

**Alternatives Considered**:
- **Mockito**: 過度なボイラープレート、リファクタリング時のメンテナンスコスト高
- **cloud_firestore_mocks package**: サードパーティ依存、Firestore APIの完全な互換性保証なし
- **Production Firestoreでテスト**: コスト発生、テストデータのクリーンアップ必要

**References**:
- [Firebase Emulator Suite - Official Docs](https://firebase.google.com/docs/emulator-suite)
- [Repository Pattern in Flutter](https://codewithandrea.com/articles/flutter-repository-pattern/)

---

### 4. Firestoreインデックス設計

**Decision**: Composite Index for Sort + Filter Queries

**Rationale**:
- タスク一覧で「期限順ソート + 完了状態フィルター」などの複合クエリを使用
- Firestoreは複合クエリに対して明示的なインデックスが必要
- インデックスは`firestore.indexes.json`で定義し、デプロイ時に自動作成

**Required Indexes**:

```json
{
  "indexes": [
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
      "collectionGroup": "projects",
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

**Index Strategy**:
1. **Default Sort (作成日時降順)**: `projectId + isCompleted + createdAt DESC`
2. **Due Date Sort**: `projectId + isCompleted + dueDate ASC`
3. **Project List**: `userId + createdAt DESC`

**Best Practices**:
- インデックスは必要最小限に（読み取り/書き込みコストに影響）
- 開発中はFirebase Consoleのエラーログから自動生成リンクを活用
- `firebase deploy --only firestore:indexes`でインデックスをデプロイ

**Alternatives Considered**:
- **Single Field Indexes**: 複合クエリで不十分（Firestoreがエラーを返す）
- **Manual Index Creation**: `firestore.indexes.json`による宣言的管理が推奨
- **Index-free Design**: ソート・フィルター機能を制限することになり、UX低下

**References**:
- [Firestore Index Management](https://firebase.google.com/docs/firestore/query-data/indexing)
- [firestore.indexes.json Format](https://firebase.google.com/docs/firestore/reference/indexes)

---

### 5. Flutter における Firestore Best Practices

**Decision**: Stream-based UI + Optimistic Updates + Error Boundaries

**Rationale**:
- **Stream-based UI**: `StreamProvider`でFirestoreリアルタイムリスナーを購読
  - データ変更が自動的にUIに反映される
  - 複数デバイス間の同期が自然に実現
- **Optimistic Updates**: 書き込み操作を即座にローカルUIに反映
  - ユーザー体験の向上（待ち時間なし）
  - エラー時はロールバックとエラー表示
- **Error Boundaries**: Firestoreエラーをキャッチし、ユーザーフレンドリーなメッセージ表示

**Implementation Pattern**:

```dart
// Stream Provider for Real-time Updates
final tasksStreamProvider = StreamProvider.family<List<Task>, String>(
  (ref, projectId) {
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromFirestore(doc))
            .toList());
  },
);

// Optimistic Update Pattern
Future<void> toggleTaskCompletion(Task task) async {
  // 1. Immediately update local state
  final updatedTask = task.copyWith(
    isCompleted: !task.isCompleted,
    completedAt: !task.isCompleted ? DateTime.now() : null,
  );
  ref.read(taskListProvider.notifier).updateLocalTask(updatedTask);
  
  try {
    // 2. Persist to Firestore
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(task.id)
        .update(updatedTask.toJson());
  } catch (e) {
    // 3. Rollback on error
    ref.read(taskListProvider.notifier).updateLocalTask(task);
    showErrorSnackbar('Failed to update task');
  }
}
```

**Performance Optimizations**:
- `limit()`でクエリサイズを制限（無限スクロールと組み合わせ）
- オフライン永続化有効化: `FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true)`
- 不要なリスナーはdispose時にキャンセル（メモリリーク防止）

**Alternatives Considered**:
- **Polling-based Updates**: リアルタイム性に劣る、Firestore読み取りコスト増加
- **Pessimistic Updates**: ユーザーが常に待たされる、UX低下
- **No Error Handling**: ネットワークエラー時にアプリがクラッシュ

**References**:
- [Get realtime updates with Cloud Firestore](https://firebase.google.com/docs/firestore/query-data/listen)
- [Offline Data in Cloud Firestore](https://firebase.google.com/docs/firestore/manage-data/enable-offline)

---

## Summary

すべての技術調査が完了し、実装に必要な意思決定が明確になりました：

| 項目 | 選択技術/パターン | 理由 |
|------|------------------|------|
| 無限スクロール | ListView.builder + Firestore Cursor | パフォーマンス最適、標準パターン |
| カーソル管理 | Riverpod StateNotifier | 状態管理が明確、テスト容易 |
| テスト戦略 | Emulator (統合) + Fake (単体) | 高速テスト + 実環境検証の両立 |
| インデックス | Composite Indexes | 複合クエリ必須、宣言的管理 |
| UI更新 | Stream + Optimistic Updates | リアルタイム性 + UX最適化 |

これらの決定に基づき、Phase 1のデータモデル設計とAPI契約定義に進みます。

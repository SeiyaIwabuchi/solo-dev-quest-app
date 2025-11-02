# Data Model: Project and Task Management

**Feature**: 002-task-management  
**Date**: 2025-11-03  
**Status**: Completed

## Overview

このドキュメントはタスク管理機能のデータモデル定義を記述します。Cloud Firestoreのコレクション構造、エンティティ属性、バリデーションルール、状態遷移を明確化します。

---

## Firestore Collections Structure

```
users/ (既存 - 001-user-authで定義)
  └── {userId}/
      └── (user profile data)

projects/ (新規)
  └── {projectId}/
      ├── id: string
      ├── userId: string (owner)
      ├── name: string
      ├── description: string | null
      ├── createdAt: timestamp
      └── updatedAt: timestamp

tasks/ (新規)
  └── {taskId}/
      ├── id: string
      ├── projectId: string (foreign key)
      ├── userId: string (owner, denormalized for security)
      ├── name: string
      ├── description: string | null
      ├── dueDate: timestamp | null
      ├── isCompleted: boolean
      ├── createdAt: timestamp
      ├── updatedAt: timestamp
      └── completedAt: timestamp | null
```

**Design Decisions**:
- **Flat Structure**: プロジェクトとタスクを別コレクションに（サブコレクションは避ける）
  - 理由: クエリの柔軟性、インデックス管理の簡素化、将来的なタスク検索機能の実装容易性
- **Denormalization**: `userId`をタスクにも保存
  - 理由: Firestoreセキュリティルールでユーザー所有権を直接検証可能
- **No Subcollections**: タスクをプロジェクトのサブコレクションにしない
  - 理由: ユーザー全体のタスク検索、複数プロジェクト間のタスク移動が困難になる

---

## Entity Definitions

### Project Entity

**Dart Model (Freezed)**:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
class Project with _$Project {
  const factory Project({
    required String id,
    required String userId,
    required String name,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
  
  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'name': name,
    'description': description,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}
```

**Validation Rules**:
- `id`: UUID v4、Firestore auto-generated
- `userId`: 非NULL、001-user-authで取得したFirebase Auth UID
- `name`: 非NULL、1-100文字、空白文字のみ不可
- `description`: NULL許可、0-500文字
- `createdAt`, `updatedAt`: サーバータイムスタンプ（`FieldValue.serverTimestamp()`）

**Indexes Required**:
```json
{
  "collectionGroup": "projects",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

---

### Task Entity

**Dart Model (Freezed)**:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String projectId,
    required String userId,
    required String name,
    String? description,
    DateTime? dueDate,
    required bool isCompleted,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? completedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      projectId: data['projectId'] as String,
      userId: data['userId'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      dueDate: data['dueDate'] != null 
          ? (data['dueDate'] as Timestamp).toDate() 
          : null,
      isCompleted: data['isCompleted'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }
  
  Map<String, dynamic> toFirestore() => {
    'projectId': projectId,
    'userId': userId,
    'name': name,
    'description': description,
    'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    'isCompleted': isCompleted,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
  };
}

extension TaskExtensions on Task {
  /// 期限超過かどうか判定
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }
}
```

**Validation Rules**:
- `id`: UUID v4、Firestore auto-generated
- `projectId`: 非NULL、有効なプロジェクトID（外部キー）
- `userId`: 非NULL、プロジェクトの所有者と一致必須
- `name`: 非NULL、1-200文字、空白文字のみ不可
- `description`: NULL許可、0-1000文字
- `dueDate`: NULL許可、未来日付推奨（過去日付も許可）
- `isCompleted`: 非NULL、デフォルトfalse
- `createdAt`, `updatedAt`: サーバータイムスタンプ
- `completedAt`: `isCompleted=true`の時のみ非NULL

**Indexes Required**:
```json
[
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
]
```

---

### Progress Metrics (Computed)

**Dart Model**:
```dart
@freezed
class ProjectProgress with _$ProjectProgress {
  const factory ProjectProgress({
    required int totalTasks,
    required int completedTasks,
    required int overdueTasks,
  }) = _ProjectProgress;
  
  const ProjectProgress._();
  
  /// 完了率 (0-100)
  double get completionRate {
    if (totalTasks == 0) return 0.0;
    return (completedTasks / totalTasks) * 100;
  }
  
  /// プロジェクト完了判定
  bool get isProjectCompleted {
    return totalTasks > 0 && completedTasks == totalTasks;
  }
}
```

**Calculation Strategy**:
- リアルタイム計算（Firestoreクエリでタスク集計）
- キャッシュ不要（タスク数が少ない場合）
- 将来的にはCloud Functionsで事前集計も検討可能

**Query Pattern**:
```dart
Future<ProjectProgress> calculateProgress(String projectId) async {
  final tasksSnapshot = await FirebaseFirestore.instance
      .collection('tasks')
      .where('projectId', isEqualTo: projectId)
      .get();
  
  final totalTasks = tasksSnapshot.docs.length;
  final completedTasks = tasksSnapshot.docs
      .where((doc) => doc.data()['isCompleted'] == true)
      .length;
  final overdueTasks = tasksSnapshot.docs
      .where((doc) {
        final data = doc.data();
        if (data['isCompleted'] == true) return false;
        if (data['dueDate'] == null) return false;
        return (data['dueDate'] as Timestamp).toDate().isBefore(DateTime.now());
      })
      .length;
  
  return ProjectProgress(
    totalTasks: totalTasks,
    completedTasks: completedTasks,
    overdueTasks: overdueTasks,
  );
}
```

---

## State Transitions

### Task State Transition

```
┌─────────────┐
│   Created   │ (isCompleted = false, completedAt = null)
│  (Initial)  │
└──────┬──────┘
       │
       │ User marks as complete
       ▼
┌─────────────┐
│  Completed  │ (isCompleted = true, completedAt = now)
└──────┬──────┘
       │
       │ User unchecks
       ▼
┌─────────────┐
│ Uncompleted │ (isCompleted = false, completedAt = null)
└─────────────┘
```

**State Rules**:
- `isCompleted = true` になるとき、`completedAt = DateTime.now()`
- `isCompleted = false` に戻るとき、`completedAt = null`
- 完了取り消しは制限なし（何度でも可能）

### Project Lifecycle

```
┌─────────────┐
│   Created   │
└──────┬──────┘
       │
       │ Add/Complete Tasks
       ▼
┌─────────────┐
│ In Progress │
└──────┬──────┘
       │
       │ All tasks completed
       ▼
┌─────────────┐
│  Completed  │ (Progress = 100%)
└──────┬──────┘
       │
       │ Uncheck task OR Add new task
       ▼
┌─────────────┐
│ In Progress │
└─────────────┘
```

**State Rules**:
- プロジェクト自体に状態フィールドなし（Progress Metricsで判定）
- `completionRate == 100%`でUI上「完了」扱い
- タスク追加で自動的に「進行中」に戻る

---

## Relationships

### Project → Tasks (One-to-Many)

```
projects/{projectId}
    └── tasks (query: where('projectId', '==', projectId))
```

**Cascade Delete Rule**:
- プロジェクト削除時、関連タスクをすべて削除
- 実装: クライアント側でバッチ削除またはCloud Functionトリガー

```dart
Future<void> deleteProject(String projectId) async {
  final batch = FirebaseFirestore.instance.batch();
  
  // Delete project
  final projectRef = FirebaseFirestore.instance
      .collection('projects')
      .doc(projectId);
  batch.delete(projectRef);
  
  // Delete all tasks
  final tasksSnapshot = await FirebaseFirestore.instance
      .collection('tasks')
      .where('projectId', isEqualTo: projectId)
      .get();
  
  for (final doc in tasksSnapshot.docs) {
    batch.delete(doc.reference);
  }
  
  await batch.commit();
}
```

### User → Projects (One-to-Many)

```
users/{userId}
    └── projects (query: where('userId', '==', userId))
```

**Access Control**:
- ユーザーは自分のプロジェクトのみ閲覧・編集可能
- Firestoreセキュリティルールで強制

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Projects Collection
    match /projects/{projectId} {
      // Read: Owner only
      allow read: if request.auth != null 
          && resource.data.userId == request.auth.uid;
      
      // Create: Authenticated users, userId must match auth
      allow create: if request.auth != null 
          && request.resource.data.userId == request.auth.uid
          && request.resource.data.name is string
          && request.resource.data.name.size() >= 1
          && request.resource.data.name.size() <= 100;
      
      // Update: Owner only, userId cannot be changed
      allow update: if request.auth != null 
          && resource.data.userId == request.auth.uid
          && request.resource.data.userId == resource.data.userId
          && request.resource.data.name is string
          && request.resource.data.name.size() >= 1
          && request.resource.data.name.size() <= 100;
      
      // Delete: Owner only
      allow delete: if request.auth != null 
          && resource.data.userId == request.auth.uid;
    }
    
    // Tasks Collection
    match /tasks/{taskId} {
      // Read: Owner only
      allow read: if request.auth != null 
          && resource.data.userId == request.auth.uid;
      
      // Create: Authenticated users, userId must match auth
      allow create: if request.auth != null 
          && request.resource.data.userId == request.auth.uid
          && request.resource.data.projectId is string
          && request.resource.data.name is string
          && request.resource.data.name.size() >= 1
          && request.resource.data.name.size() <= 200
          && request.resource.data.isCompleted == false;
      
      // Update: Owner only, projectId and userId cannot be changed
      allow update: if request.auth != null 
          && resource.data.userId == request.auth.uid
          && request.resource.data.projectId == resource.data.projectId
          && request.resource.data.userId == resource.data.userId
          && request.resource.data.name is string
          && request.resource.data.name.size() >= 1
          && request.resource.data.name.size() <= 200;
      
      // Delete: Owner only
      allow delete: if request.auth != null 
          && resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## Data Migration Strategy

**Initial Setup (no migration needed)**:
- 新規コレクション作成: `projects`, `tasks`
- インデックス作成: `firebase deploy --only firestore:indexes`
- セキュリティルール更新: `firebase deploy --only firestore:rules`

**Future Schema Changes**:
1. 新フィールド追加時: NULL許可で追加、既存ドキュメントは影響なし
2. フィールド削除時: アプリ側でフィールドを無視、後日バッチ削除
3. データ型変更時: 移行スクリプト（Cloud Functions）で全ドキュメント更新

---

## Summary

データモデルの定義が完了しました：

| エンティティ | コレクション | 主要属性 | リレーション |
|------------|-------------|---------|-------------|
| Project | `projects/` | id, userId, name, description | 1→多 Tasks |
| Task | `tasks/` | id, projectId, userId, name, isCompleted | 多→1 Project |
| Progress | (計算値) | totalTasks, completedTasks, completionRate | - |

Firestoreインデックス、セキュリティルール、バリデーションルールがすべて定義されました。次のPhaseでAPIコントラクトを定義します。

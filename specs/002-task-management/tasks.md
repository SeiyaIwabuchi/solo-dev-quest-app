# Tasks: Project and Task Management

**Feature Branch**: `002-task-management`  
**Input**: Design documents from `/specs/002-task-management/`
**Prerequisites**: ✅ plan.md, ✅ spec.md, ✅ research.md, ✅ data-model.md, ✅ contracts/

**Tests**: テストタスクは含まれていません（仕様で明示的に要求されていないため）

**Organization**: タスクはユーザーストーリー別に整理され、各ストーリーを独立して実装・テスト可能

---

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並列実行可能（異なるファイル、依存関係なし）
- **[Story]**: このタスクが属するユーザーストーリー（US1, US2, US3等）
- 説明には正確なファイルパスを含む

---

## Phase 0: Project Setup (Shared Infrastructure)

**Purpose**: Flutter + Firebase基盤構築と依存関係インストール

- [X] T001 Add dependencies to flutter_app/pubspec.yaml: flutter_riverpod ^2.6.1, cloud_firestore ^5.5.1, freezed ^2.5.7, freezed_annotation ^2.4.4, json_annotation ^4.9.0, build_runner ^2.4.13, json_serializable ^6.8.0
- [X] T002 Run `fvm flutter pub get` to install dependencies
- [X] T003 [P] Create lib/core/exceptions/ directory and add validation_exception.dart, not_found_exception.dart, unauthorized_exception.dart
- [X] T004 [P] Create lib/features/task_management/ directory structure: data/models/, data/repositories/, domain/enums/, presentation/controllers/, presentation/screens/, presentation/widgets/, providers/
- [X] T005 Setup Firestore indexes in firebase/firestore.indexes.json (4 composite indexes per data-model.md)
- [X] T006 Setup Firestore security rules in firebase/firestore.rules for projects and tasks collections
- [X] T007 Deploy Firestore rules and indexes: `cd firebase && firebase deploy --only firestore`

---

## Phase 1: Foundational (Blocking Prerequisites for MVP)

**Purpose**: MVP（User Story 1-4）に必須のデータモデルとリポジトリ基盤を完成させる

**⚠️ CRITICAL**: このフェーズが完了するまで、ユーザーストーリー実装は開始できない

**Constitution Principle III準拠**: Firebase-First Architecture（Firestore使用）

- [X] T008 [P] Create Project model with Freezed in lib/features/task_management/data/models/project.dart (id, userId, name, description, createdAt, updatedAt)
- [X] T009 [P] Create Task model with Freezed in lib/features/task_management/data/models/task.dart (id, projectId, userId, name, description, dueDate, isCompleted, createdAt, updatedAt, completedAt)
- [X] T010 [P] Create TaskStatistics model with Freezed in lib/features/task_management/data/models/task_statistics.dart (totalTasks, completedTasks, overdueTasks, completionRate, isProjectCompleted)
- [X] T011 [P] Create TaskSortBy enum in lib/features/task_management/domain/enums/task_sort_by.dart (createdAt, dueDate)
- [X] T012 Run Freezed code generation: `cd flutter_app && fvm flutter pub run build_runner build --delete-conflicting-outputs`
- [X] T013 Create IProjectRepository interface in lib/features/task_management/data/repositories/i_project_repository.dart (watchUserProjects, watchProject, createProject, updateProject, deleteProject, exists)
- [X] T014 Create ITaskRepository interface in lib/features/task_management/data/repositories/i_task_repository.dart (watchProjectTasks, watchTask, createTask, updateTask, toggleTaskCompletion, deleteTask, getProjectTaskStatistics, exists)
- [X] T015 Implement FirestoreProjectRepository in lib/features/task_management/data/repositories/firestore_project_repository.dart with all IProjectRepository methods
- [X] T016 Implement FirestoreTaskRepository in lib/features/task_management/data/repositories/firestore_task_repository.dart with all ITaskRepository methods
- [X] T017 [P] Create repository providers in lib/features/task_management/providers/repository_providers.dart (projectRepositoryProvider, taskRepositoryProvider)

**Checkpoint**: データ層完成 - ユーザーストーリー実装を並行開始可能

---

## Phase 2: User Story 1 - Create New Project (Priority: P1) 🎯 MVP

**Goal**: 個人開発者が新しい開発プロジェクトを作成し、プロジェクト名と簡単な説明を設定して、開発作業を組織化できる

**Independent Test**: ユーザーがプロジェクト作成画面からプロジェクト名と説明を入力し、「作成」ボタンを押してプロジェクトリストに新しいプロジェクトが表示される

**Constitution Check**: 
- Principle I: プロジェクト作成はタスク管理の入口であり、モチベーション維持の起点
- Principle II: MVP-First - 最優先機能
- Principle III: Firestore使用

### Implementation for User Story 1

- [X] T018 [P] [US1] Create project providers in lib/features/task_management/providers/project_providers.dart (userProjectsProvider, projectProvider using StreamProvider)
- [X] T019 [P] [US1] Create ProjectListController in lib/features/task_management/presentation/controllers/project_list_controller.dart (handles project creation logic, validation)
- [X] T020 [US1] Create ProjectListScreen in lib/features/task_management/presentation/screens/project_list_screen.dart (displays all user projects, FAB for new project)
- [X] T021 [P] [US1] Create ProjectCard widget in lib/features/task_management/presentation/widgets/project_card.dart (displays project name, description, progress rate, creation date)
- [X] T022 [P] [US1] Create CreateProjectDialog widget in lib/features/task_management/presentation/widgets/create_project_dialog.dart (input form for name and description with validation)
- [X] T023 [US1] Implement project creation flow: form validation (name 1-100 chars, description 0-500 chars), Firestore write, navigation to project detail
- [X] T024 [US1] Add empty state UI in ProjectListScreen (no projects message + create button)
- [X] T025 [US1] Add loading states and error handling with Riverpod AsyncValue

**Checkpoint**: User Story 1完了 - プロジェクト作成機能が独立してテスト可能

---

## Phase 3: User Story 2 - View Project List (Priority: P1) 🎯 MVP

**Goal**: ユーザーが作成したすべてのプロジェクトを一覧表示し、各プロジェクトの進捗状況を確認できる

**Independent Test**: ユーザーがホーム画面またはプロジェクトタブを開き、作成済みのプロジェクトが一覧表示され、各プロジェクトの名前・説明・進捗率が確認できる

**Constitution Check**: 
- Principle I: プロジェクト一覧はユーザーの進捗を可視化しモチベーション維持に貢献
- Principle II: MVP-First - User Story 1と同等に重要
- Principle VI: Riverpod StreamProviderでリアルタイムUI更新

### Implementation for User Story 2

- [X] T026 [P] [US2] Create ProgressIndicatorWidget in lib/features/task_management/presentation/widgets/progress_indicator_widget.dart (displays completion percentage with visual bar)
- [X] T027 [US2] Enhance ProjectCard to display progress rate using ProgressIndicatorWidget
- [X] T028 [US2] Add project statistics calculation logic in ProjectListController (calls taskRepository.getProjectTaskStatistics)
- [X] T029 [US2] Implement project card tap navigation to project detail screen
- [X] T030 [US2] Add Firestore realtime listener for project list updates (via Riverpod StreamProvider)
- [X] T031 [US2] Handle empty project list state (已在US1实现，验证即可)
- [X] T032 [US2] Add pull-to-refresh functionality on ProjectListScreen

**Checkpoint**: User Story 2完了 - プロジェクト一覧表示とリアルタイム更新が動作

---

## Phase 4: User Story 3 - Create Task within Project (Priority: P1) 🎯 MVP

**Goal**: ユーザーがプロジェクト内に具体的なタスクを作成し、タスク名・説明・期限を設定して開発作業を細分化できる

**Independent Test**: ユーザーがプロジェクト詳細画面から「新規タスク」ボタンをタップし、タスク情報を入力して作成後、タスク一覧に新しいタスクが表示される

**Constitution Check**: 
- Principle I: タスク作成はモチベーション維持機能（進捗可視化、AI褒め）の前提条件
- Principle II: MVP核心機能
- Principle III: Firestoreでタスク永続化

### Implementation for User Story 3

- [X] T033 [P] [US3] Create task providers in lib/features/task_management/providers/task_providers.dart (projectTasksProvider, taskProvider, projectStatisticsProvider using StreamProvider/FutureProvider)
- [X] T034 [P] [US3] Create TaskListController in lib/features/task_management/presentation/controllers/task_list_controller.dart (infinite scroll state management, load initial/more tasks)
- [X] T035 [US3] Create ProjectDetailScreen in lib/features/task_management/presentation/screens/project_detail_screen.dart (displays project info + task list, FAB for new task)
- [X] T036 [P] [US3] Create TaskTile widget in lib/features/task_management/presentation/widgets/task_tile.dart (displays task name, description, due date, checkbox for completion)
- [X] T037 [P] [US3] Create TaskEditScreen in lib/features/task_management/presentation/screens/task_edit_screen.dart (form for creating/editing task with name, description, due date)
- [X] T038 [US3] Implement task creation flow: form validation (name 1-200 chars, description 0-1000 chars), Firestore write with projectId and userId
- [X] T039 [US3] Add due date picker to TaskEditScreen (DatePicker widget)
- [X] T040 [US3] Display overdue indicator on TaskTile (red color when dueDate < now && !isCompleted)
- [X] T041 [US3] Add empty state UI in ProjectDetailScreen (no tasks message + create button)
- [X] T042 [US3] Add loading states and error handling for task operations

**Checkpoint**: User Story 3完了 - タスク作成機能が動作、プロジェクト詳細画面で表示

---

## Phase 5: User Story 4 - Mark Task as Complete (Priority: P1) 🎯 MVP

**Goal**: ユーザーがタスクを完了したときに、タスクを「完了」状態にマークし、進捗状況を更新できる

**Independent Test**: ユーザーがタスク一覧から未完了タスクのチェックボックスをタップし、タスクが完了状態になり、プロジェクトの進捗率が更新される

**Constitution Check**: 
- Principle I: タスク完了はモチベーション維持機能（AI褒め、進捗可視化）の最重要トリガー
- Principle IV: AI賞賛機能との非同期連携
- Principle VI: Optimistic UpdatesでレスポンシブなUI

### Implementation for User Story 4

- [X] T043 [US4] Implement task completion toggle logic in TaskListController (optimistic update + toggleTaskCompletion call)
- [X] T044 [US4] Add checkbox interaction to TaskTile (onTap triggers completion toggle)
- [X] T045 [US4] Update TaskTile UI for completed tasks (strikethrough text, checkmark icon, gray color)
- [X] T046 [US4] Implement completedAt timestamp recording in FirestoreTaskRepository.toggleTaskCompletion
- [X] T047 [US4] Add real-time progress rate update in ProjectDetailScreen (watches projectStatisticsProvider)
- [X] T048 [US4] Implement completion undo (tap checkbox again to uncheck, completedAt = null)
- [X] T049 [P] [US4] Create CompletionCelebrationDialog widget in lib/features/task_management/presentation/widgets/completion_celebration_dialog.dart (shown when project reaches 100%)
- [X] T050 [US4] Add project completion detection in ProjectDetailController: when completionRate == 100%, show CompletionCelebrationDialog
- [X] T051 [US4] Integrate AI praise API (non-blocking async call after task completion - placeholder for future AI integration from 001-user-auth)
- [X] T052 [US4] Add toast/snackbar notification for AI praise message when it arrives
- [X] T053 [US4] Handle error states when task completion fails (rollback optimistic update, show error message)

**Checkpoint**: User Story 4完了 - タスク完了機能、進捗率更新、プロジェクト完了祝福が動作

---

## Phase 6: User Story 5 - Edit Project and Task (Priority: P2)

**Goal**: ユーザーが作成済みのプロジェクトやタスクの情報（名前、説明、期限等）を編集して、変更内容を保存できる

**Independent Test**: ユーザーがプロジェクト詳細画面またはタスク詳細画面で「編集」ボタンをタップし、情報を変更して保存後、変更内容が反映される

**Constitution Check**: 
- Principle II: P2機能 - MVP後の改善
- Principle VI: フォームバリデーションとエラーハンドリング

### Implementation for User Story 5

- [X] T054 [P] [US5] Create ProjectDetailController in lib/features/task_management/presentation/controllers/project_detail_controller.dart (handles project edit logic)
- [X] T055 [US5] Add edit mode to ProjectDetailScreen (edit button, inline form or dialog)
- [X] T056 [US5] Implement project update flow: validation (name 1-100 chars), Firestore update, UI refresh
- [X] T057 [US5] Add edit mode to TaskEditScreen (reuse for both create and edit, pass taskId for edit)
- [X] T058 [US5] Implement task update flow: validation (name 1-200 chars), Firestore update via taskRepository.updateTask
- [X] T059 [US5] Add cancel button to edit forms (discard changes, return to previous screen)
- [X] T060 [US5] Handle concurrent edit conflicts (Last Write Wins strategy per research.md)
- [X] T061 [US5] Add loading states during update operations

**Checkpoint**: User Story 5完了 - プロジェクトとタスクの編集機能が動作

---

## Phase 7: User Story 6 - Delete Project and Task (Priority: P2)

**Goal**: ユーザーが不要になったプロジェクトやタスクを削除し、データを整理できる

**Independent Test**: ユーザーがプロジェクト詳細画面またはタスク一覧から「削除」ボタンをタップし、確認ダイアログで削除を確定後、プロジェクトまたはタスクが一覧から消える

**Constitution Check**: 
- Principle II: P2機能 - 基本CRUDの最後
- Principle III: Firestoreバッチ削除でカスケード削除実現

### Implementation for User Story 6

- [X] T062 [P] [US6] Create DeleteConfirmationDialog widget in lib/shared/widgets/delete_confirmation_dialog.dart (reusable confirmation dialog)
- [X] T063 [US6] Add delete button to ProjectDetailScreen (shows DeleteConfirmationDialog with warning for tasks count)
- [X] T064 [US6] Implement cascade delete in FirestoreProjectRepository.deleteProject (batch delete project + all tasks)
- [X] T065 [US6] Add swipe-to-delete gesture to TaskTile (shows delete button on swipe left)
- [X] T066 [US6] Implement task delete in FirestoreTaskRepository.deleteTask
- [X] T067 [US6] Add progress rate recalculation after task deletion
- [X] T068 [US6] Handle deletion errors (show error message, retry option)
- [X] T069 [US6] Navigate back to project list after project deletion

**Checkpoint**: User Story 6完了 - プロジェクトとタスクの削除機能が動作

---

## Phase 8: User Story 7 - Sort and Filter Tasks (Priority: P3)

**Goal**: ユーザーがタスク一覧を並び替えたり、フィルター（未完了/完了/期限順等）をかけて、優先的に取り組むべきタスクを見つけやすくできる

**Independent Test**: ユーザーがタスク一覧画面でフィルター・ソートオプションを選択し、タスクの表示順序や表示内容が変更される

**Constitution Check**: 
- Principle II: P3機能 - UX向上だが基本機能動作後に実装
- Principle VI: Riverpodでソート/フィルター状態管理

### Implementation for User Story 7

- [ ] T070 [P] [US7] Create TaskFilterState model in lib/features/task_management/domain/enums/task_filter_state.dart (all, completed, uncompleted, overdue)
- [ ] T071 [US7] Add sort and filter controls to ProjectDetailScreen (dropdown or bottom sheet)
- [ ] T072 [US7] Implement sort by creation date (descending - default) in TaskListController
- [ ] T073 [US7] Implement sort by due date (ascending) in TaskListController
- [ ] T074 [US7] Implement filter by completed status (show only completed/uncompleted) in TaskListController
- [ ] T075 [US7] Implement filter by overdue status (show only overdue tasks) in TaskListController
- [ ] T076 [US7] Update Firestore query in FirestoreTaskRepository.watchProjectTasks to support sortBy and filterCompleted parameters
- [ ] T077 [US7] Add visual indicators for active filters (chip badges)
- [ ] T078 [US7] Add clear filter button

**Checkpoint**: User Story 7完了 - ソート・フィルター機能が動作

---

## Phase 9: Infinite Scroll Implementation (Enhancement)

**Purpose**: タスク数が多い場合のパフォーマンス最適化

**Constitution Check**: 
- Principle II: 段階的機能追加
- Research.md Topic 1準拠: ListView.builder + Firestore cursor pagination

- [X] T079 Implement pagination state in TaskListController (page size = 30, hasMore flag, lastDocument cursor)
- [X] T080 Add scroll listener to ProjectDetailScreen ListView (detects bottom reached, triggers loadMore)
- [X] T081 Implement loadMore method in TaskListController (fetches next page with startAfterDoc cursor)
- [X] T082 Add loading indicator at bottom of task list when loading more tasks
- [X] T083 Handle end of list state (no more tasks to load)
- [X] T084 Add pull-to-refresh to reload first page of tasks

**Checkpoint**: 無限スクロール完成 - 100+タスクでも快適に動作

---

## Phase 10: Offline Support & Sync (Enhancement)

**Purpose**: ネットワーク切断時のローカル操作とオンライン復帰時の自動同期

**Constitution Check**: 
- FR-013準拠: Last Write Wins + オフライン変更タイムスタンプ記録
- Research.md Topic 5準拠: Optimistic updates

- [X] T085 Enable Firestore offline persistence in main.dart (FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true))
- [X] T086 Add network connectivity monitoring (connectivity_plus package)
- [X] T087 Add offline indicator in app bar (shows when offline)
- [X] T088 Implement optimistic updates for all mutations (create, update, delete, toggle completion)
- [X] T089 Add conflict resolution handling (Last Write Wins strategy)
- [X] T090 Add offline operation queue visualization (optional: show pending syncs)
- [X] T091 Add retry mechanism for failed syncs when connection restored

**Checkpoint**: オフライン対応完成 - ネットワーク切断中も操作可能

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: 全体の品質向上とドキュメント整備

- [ ] T092 [P] Add Firebase Analytics events for key actions (project_created, task_created, task_completed, project_completed)
- [ ] T093 [P] Add Firebase Crashlytics error reporting
- [ ] T094 [P] Create ErrorBoundary widget in lib/shared/widgets/error_boundary.dart (catches errors, shows user-friendly message)
- [ ] T095 Add app-wide loading overlay in lib/shared/widgets/loading_overlay.dart
- [ ] T096 Implement app theming in lib/core/constants/app_theme.dart (Material Design 3 colors, text styles)
- [ ] T097 Add l10n (日本語ローカライゼーション) for all user-facing strings
- [ ] T098 Performance optimization: add const constructors where possible
- [ ] T099 Code cleanup: run `fvm dart fix --apply` and address linter warnings
- [ ] T100 Update quickstart.md with final implementation notes
- [ ] T101 Create demo data script for testing (creates sample projects and tasks)
- [ ] T102 Run integration tests with Firebase Emulator
- [ ] T103 Deploy to Firebase Hosting (web version for demo)

**Checkpoint**: 全機能完成 - リリース準備完了

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 0)**: No dependencies - can start immediately
- **Foundational (Phase 1)**: Depends on Phase 0 completion - **BLOCKS all user stories**
- **User Stories (Phase 2-8)**: All depend on Phase 1 completion
  - P1 stories (US1-US4): MVP core - implement first in order
  - P2 stories (US5-US6): Basic CRUD completion - implement after P1
  - P3 stories (US7): UX enhancement - implement after P2
- **Enhancements (Phase 9-10)**: Depend on core user stories (Phase 2-5)
- **Polish (Phase 11)**: Depends on all desired features being complete

### User Story Dependencies

- **User Story 1 (P1)**: Independent - only depends on Phase 1
- **User Story 2 (P1)**: Independent - only depends on Phase 1, integrates with US1
- **User Story 3 (P1)**: Depends on US1 (needs project to exist), but independently testable
- **User Story 4 (P1)**: Depends on US3 (needs tasks to exist), but independently testable
- **User Story 5 (P2)**: Depends on US1+US3 (needs projects and tasks), but independently testable
- **User Story 6 (P2)**: Depends on US1+US3 (needs projects and tasks), but independently testable
- **User Story 7 (P3)**: Depends on US3+US4 (needs task list to filter/sort), but independently testable

### Within Each User Story

- Controllers before screens (controllers manage state for screens)
- Widgets can be built in parallel with controllers
- Screens integrate controllers and widgets
- Loading/error states added last within each story

### Parallel Opportunities

**Phase 0 (Setup)**:
- T003, T004 can run in parallel (different directories)

**Phase 1 (Foundational)**:
- T008, T009, T010, T011 can run in parallel (different model files)
- T017 waits for T015, T016

**Phase 2 (US1)**:
- T018, T019, T021, T022 can run in parallel (different files)

**Phase 3 (US2)**:
- T026, T027 can run in parallel if T026 is a separate widget

**Phase 4 (US3)**:
- T033, T034, T036, T037 can run in parallel (different files)

**Phase 5 (US4)**:
- T049 can be built in parallel with T043-T048

**Phase 6 (US5)**:
- T054, T055 can run in parallel

**Phase 7 (US6)**:
- T062 can be built in parallel with T063

**Phase 8 (US7)**:
- T070 can be built in parallel with T071

**Phase 11 (Polish)**:
- T092, T093, T094, T095, T096 can run in parallel (different files)

---

## Parallel Example: User Story 1

```bash
# Launch Phase 1 models together:
Task: T008 [P] Create Project model with Freezed
Task: T009 [P] Create Task model with Freezed
Task: T010 [P] Create TaskStatistics model with Freezed
Task: T011 [P] Create TaskSortBy enum

# Launch User Story 1 components together:
Task: T018 [P] [US1] Create project providers
Task: T019 [P] [US1] Create ProjectListController
Task: T021 [P] [US1] Create ProjectCard widget
Task: T022 [P] [US1] Create CreateProjectDialog widget
```

---

## Implementation Strategy

### MVP First (User Stories 1-4 Only)

1. Complete Phase 0: Setup → Dependencies installed, directories created
2. Complete Phase 1: Foundational → **CRITICAL** - Data models and repositories ready
3. Complete Phase 2: User Story 1 → **STOP and VALIDATE** - Project creation works
4. Complete Phase 3: User Story 2 → **STOP and VALIDATE** - Project list works
5. Complete Phase 4: User Story 3 → **STOP and VALIDATE** - Task creation works
6. Complete Phase 5: User Story 4 → **STOP and VALIDATE** - Task completion + progress tracking works
7. **MVP COMPLETE**: Deploy/demo with core task management functionality

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (Project creation MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo (Project list + progress)
4. Add User Story 3 → Test independently → Deploy/Demo (Task creation)
5. Add User Story 4 → Test independently → Deploy/Demo (Task completion + celebration)
6. **MVP Release**: Core value delivered
7. Add User Story 5 → Edit functionality
8. Add User Story 6 → Delete functionality
9. Add User Story 7 → Sort/filter functionality
10. Add Phase 9 → Infinite scroll for scale
11. Add Phase 10 → Offline support for reliability

### Parallel Team Strategy

With multiple developers:

1. **Team completes Phase 0 + Phase 1 together** → Foundation ready
2. Once Phase 1 is done:
   - **Developer A**: User Story 1 → User Story 2 (projects)
   - **Developer B**: User Story 3 → User Story 4 (tasks)
   - **Developer C**: Phase 11 polish tasks (analytics, theming)
3. After MVP (US1-US4):
   - **Developer A**: User Story 5 (edit)
   - **Developer B**: User Story 6 (delete)
   - **Developer C**: User Story 7 (sort/filter)
4. Final phase:
   - **Developer A**: Phase 9 (infinite scroll)
   - **Developer B**: Phase 10 (offline)
   - **Developer C**: Phase 11 cleanup

---

## Task Summary

**Total Tasks**: 103
**MVP Tasks (Phase 0-5)**: 53 tasks
**P2 Tasks (Phase 6-7)**: 15 tasks
**P3 Tasks (Phase 8)**: 9 tasks
**Enhancement Tasks (Phase 9-10)**: 13 tasks
**Polish Tasks (Phase 11)**: 12 tasks

**Task Count per User Story**:
- US1 (Create Project): 8 tasks
- US2 (View Project List): 7 tasks
- US3 (Create Task): 10 tasks
- US4 (Mark Task Complete): 11 tasks
- US5 (Edit): 8 tasks
- US6 (Delete): 8 tasks
- US7 (Sort/Filter): 9 tasks

**Parallel Opportunities Identified**:
- Phase 1: 4 models in parallel
- User Story 1: 4 components in parallel
- Polish: 5 tasks in parallel

**Suggested MVP Scope**:
- Phase 0-5 (53 tasks) = User Stories 1-4 = Core project and task management with completion tracking

---

## Notes

- [P] tasks = different files, no dependencies within phase
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group of tasks
- Stop at any checkpoint to validate story independently
- Verify constitution compliance at each phase completion
- Use Firebase Emulator for all local development and testing
- Follow quickstart.md for detailed implementation guidance

---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: The examples below include test tasks. Tests are OPTIONAL - only include them if explicitly requested in the feature specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

**Solo Dev Quest App uses Flutter + Firebase Architecture**:
- **Flutter app**: `lib/features/[feature-name]/` (data, domain, presentation, providers)
- **Shared code**: `lib/shared/` (widgets, models, services)
- **Tests**: `test/unit/`, `test/widget/`, `test/integration/`
- **Cloud Functions**: `functions/src/[module-name]/`
- **Assets**: `assets/images/`, `assets/animations/`, `assets/fonts/`

**Constitution Alignment**:
- すべてのタスクは憲法原則（特にPrinciple I, II, III）に準拠すること
- Firebaseサービス（Auth, Firestore, Functions）を優先的に使用すること
- RiverpodによるSolo Dev 管理を徹底すること
- AI機能は抽象化レイヤーを通してCloud Functionsから呼び出すこと

<!-- 
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.
  
  The /speckit.tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Endpoints from contracts/
  
  Tasks MUST be organized by user story so each story can be:
  - Implemented independently
  - Tested independently
  - Delivered as an MVP increment
  
  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Phase 0: Project Setup (Shared Infrastructure)

**Purpose**: Flutter + Firebase プロジェクト初期化と基本構造構築

- [ ] T001 Create Flutter project with Riverpod, go_router, freezed dependencies
- [ ] T002 Initialize Firebase project (Auth, Firestore, Functions, Storage)
- [ ] T003 [P] Setup Firebase Emulator Suite for local development
- [ ] T004 [P] Configure analysis_options.yaml (linting, formatting)
- [ ] T005 [P] Create lib/core/ directory structure (constants, utils, errors, router)
- [ ] T006 Setup CI/CD with GitHub Actions (Flutter test, build, deploy)

---

## Phase 1: Foundational (Blocking Prerequisites for MVP)

**Purpose**: MVP（Phase 1）に必須のコアインフラを完成させる

**⚠️ CRITICAL**: このフェーズが完了するまで、ユーザーストーリー実装は開始できない

**Constitution Principle III準拠**: Firebase-First Architecture

- [ ] T007 Setup Firebase Authentication (email/password, Google Sign-In)
- [ ] T008 [P] Create Firestore security rules基盤（users, tasks, devcoins collections）
- [ ] T009 [P] Implement base Riverpod providers (authProvider, userProvider)
- [ ] T010 Create lib/shared/widgets/ common components (AppButton, LoadingOverlay等)
- [ ] T011 [P] Setup Firebase Cloud Functions基盤（TypeScript + ESLint + Jest）
- [ ] T012 Implement AI abstraction layer in functions/src/ai/ (Claude + OpenAI fallback)
- [ ] T013 Setup error handling & logging infrastructure (Crashlytics, structured logs)
- [ ] T014 Configure go_router with authentication guard
- [ ] T015 Setup DevCoin経済システムの基本モデル（Firestore schema定義）

**Checkpoint**: MVP基盤完成 - ユーザーストーリー実装を並行開始可能

---

## Phase 2: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

**Constitution Check**: Principle I（モチベーション維持）、Principle II（MVP-First）への貢献を明記

### Tests for User Story 1 (OPTIONAL - only if tests requested) ⚠️

> **NOTE: Constitution Principle VI準拠 - Widget Test + Integration Test推奨**
> **Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T016 [P] [US1] Widget test for [Component] in test/widget/[feature]/[component]_test.dart
- [ ] T017 [P] [US1] Integration test for [user journey] in test/integration/[feature]/[journey]_test.dart

### Implementation for User Story 1

- [ ] T018 [P] [US1] Create domain models using freezed in lib/features/[feature]/domain/[entity].dart
- [ ] T019 [P] [US1] Create repository interface in lib/features/[feature]/domain/[repository].dart
- [ ] T020 [US1] Implement Firebase repository in lib/features/[feature]/data/[repository]_impl.dart
- [ ] T021 [P] [US1] Create Riverpod providers in lib/features/[feature]/providers/[provider].dart
- [ ] T022 [US1] Implement presentation layer (screens/widgets) in lib/features/[feature]/presentation/
- [ ] T023 [US1] Add Firestore security rules for [feature] collections
- [ ] T024 [US1] (If AI needed) Implement Cloud Function in functions/src/[feature]/[function].ts
- [ ] T025 [US1] Add error handling & loading states (Riverpod AsyncValue)
- [ ] T026 [US1] Add Firebase Analytics events for user story tracking

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 2 (OPTIONAL - only if tests requested) ⚠️

- [ ] T018 [P] [US2] Contract test for [endpoint] in tests/contract/test_[name].py
- [ ] T019 [P] [US2] Integration test for [user journey] in tests/integration/test_[name].py

### Implementation for User Story 2

- [ ] T020 [P] [US2] Create [Entity] model in src/models/[entity].py
- [ ] T021 [US2] Implement [Service] in src/services/[service].py
- [ ] T022 [US2] Implement [endpoint/feature] in src/[location]/[file].py
- [ ] T023 [US2] Integrate with User Story 1 components (if needed)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 3 (OPTIONAL - only if tests requested) ⚠️

- [ ] T024 [P] [US3] Contract test for [endpoint] in tests/contract/test_[name].py
- [ ] T025 [P] [US3] Integration test for [user journey] in tests/integration/test_[name].py

### Implementation for User Story 3

- [ ] T026 [P] [US3] Create [Entity] model in src/models/[entity].py
- [ ] T027 [US3] Implement [Service] in src/services/[service].py
- [ ] T028 [US3] Implement [endpoint/feature] in src/[location]/[file].py

**Checkpoint**: All user stories should now be independently functional

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] TXXX [P] Documentation updates in docs/
- [ ] TXXX Code cleanup and refactoring
- [ ] TXXX Performance optimization across all stories
- [ ] TXXX [P] Additional unit tests (if requested) in tests/unit/
- [ ] TXXX Security hardening
- [ ] TXXX Run quickstart.md validation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Models before services
- Services before endpoints
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together (if tests requested):
Task: "Contract test for [endpoint] in tests/contract/test_[name].py"
Task: "Integration test for [user journey] in tests/integration/test_[name].py"

# Launch all models for User Story 1 together:
Task: "Create [Entity1] model in src/models/[entity1].py"
Task: "Create [Entity2] model in src/models/[entity2].py"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence

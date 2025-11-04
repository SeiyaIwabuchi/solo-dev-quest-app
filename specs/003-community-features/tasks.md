# Tasks: Phase 2 コミュニティ機能

**Input**: Design documents from `/specs/003-community-features/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: このフィーチャーでは統合テストが計画されています。各ユーザーストーリーに対応するテストタスクを含みます。

**Organization**: タスクはユーザーストーリーごとにグループ化され、各ストーリーを独立して実装・テスト可能にします。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並行実行可能（異なるファイル、未完了タスクへの依存なし）
- **[Story]**: このタスクが属するユーザーストーリー（例: US1, US2, US3）
- 説明には正確なファイルパスを含む

## Path Conventions

**Solo Dev Quest App uses Flutter + Firebase Architecture**:
- **Flutter app**: `lib/features/community/` (data, domain, presentation, providers)
- **Shared code**: `lib/shared/` (widgets, models, services)
- **Tests**: `test/unit/`, `test/widget/`, `test/integration/`
- **Cloud Functions**: `functions/src/community/`
- **Assets**: `assets/images/`, `assets/animations/`

**Constitution Alignment**:
- すべてのタスクは憲法原則（特にPrinciple I, II, III, VI, VII）に準拠
- Firebaseサービス（Auth, Firestore, Functions）を優先的に使用
- Riverpodによる状態管理を徹底
- AI機能は抽象化レイヤーを通してCloud Functionsから呼び出す

---

## Phase 0: Project Setup (Shared Infrastructure)

**Purpose**: Phase 2コミュニティ機能の基本構造構築

- [ ] T001 Create lib/features/community/ directory structure (data, domain, presentation, providers)
- [ ] T002 [P] Add new dependencies to flutter_app/pubspec.yaml (in_app_purchase, cached_network_image, sqflite, flutter_appauth)
- [ ] T003 [P] Add SNS SDK dependencies to functions/package.json (twitter-api-v2, axios, facebook-nodejs-business-sdk)
- [ ] T004 [P] Create functions/src/community/ directory structure
- [ ] T005 [P] Setup environment variables in functions/.env (TWITTER_CLIENT_ID, META_APP_ID, INSTAGRAM_APP_ID, APPLE_SHARED_SECRET)
- [ ] T006 [P] Create Firestore indexes in firebase/firestore.indexes.json (questions, answers collections)
- [ ] T007 Run firebase deploy --only firestore:indexes to create indexes

---

## Phase 1: Foundational (Blocking Prerequisites for All User Stories)

**Purpose**: Q&A、SNS統合、プレミアムプランに共通する基盤を完成させる

**⚠️ CRITICAL**: このフェーズが完了するまで、ユーザーストーリー実装は開始できない

**Constitution Principle III準拠**: Firebase-First Architecture

- [ ] T008 Update firebase/firestore.rules with Phase 2 security rules (questions, answers, comments, content_reports collections)
- [ ] T009 [P] Create lib/features/community/domain/models/question.dart with freezed
- [ ] T010 [P] Create lib/features/community/domain/models/answer.dart with freezed
- [ ] T011 [P] Create lib/features/community/domain/models/comment.dart with freezed
- [ ] T012 [P] Create lib/features/community/domain/models/content_report.dart with freezed
- [ ] T013 [P] Create lib/features/community/domain/models/hashtag_post.dart with freezed
- [ ] T014 [P] Create lib/features/community/domain/models/premium_subscription.dart with freezed
- [ ] T015 Create lib/features/community/domain/repositories/question_repository.dart interface
- [ ] T016 Create lib/features/community/domain/repositories/answer_repository.dart interface
- [ ] T017 Create lib/features/community/domain/repositories/sns_repository.dart interface
- [ ] T018 Create lib/features/community/domain/repositories/subscription_repository.dart interface
- [ ] T019 Create lib/shared/widgets/category_tag_chip.dart (カテゴリタグUI部品)
- [ ] T020 [P] Create lib/shared/widgets/devcoin_balance_display.dart (DevCoin残高表示部品)
- [ ] T021 [P] Create lib/shared/widgets/markdown_viewer.dart (Markdown表示部品)
- [ ] T022 Deploy firebase deploy --only firestore:rules

**Checkpoint**: MVP基盤完成 - ユーザーストーリー実装を並行開始可能

---

## Phase 2: User Story 1 - 技術的質問の投稿と閲覧 (Priority: P1) 🎯 MVP

**Goal**: 開発者が技術的な壁に直面した際、Q&Aプラットフォームに質問を投稿し(10 DevCoin消費)、他の開発者からの回答を得られる。過去の質問・回答は誰でも無料で閲覧可能。

**Independent Test**: DevCoinを持つユーザーが質問を投稿し、他のユーザーがその質問を閲覧できることを確認。

**Constitution Check**: 
- ✅ Principle I（知識不足解決で開発者が孤独を感じない）
- ✅ Principle II（MVP第一、Phase 2の最優先機能）
- ✅ Principle V（DevCoin 10消費、無料/有料分離）

### Tests for User Story 1

- [ ] T023 [P] [US1] Integration test for question post flow in test/integration/community/question_post_test.dart
- [ ] T024 [P] [US1] Integration test for question list & detail view in test/integration/community/question_view_test.dart
- [ ] T025 [P] [US1] Widget test for QuestionListItem in test/widget/community/question_list_item_test.dart

### Cloud Functions for User Story 1

- [ ] T026 [P] [US1] Implement postQuestion Cloud Function in functions/src/community/post_question.ts (Firestoreトランザクションで残高チェック→減算→質問作成)
- [ ] T027 [P] [US1] Add duplicate question prevention logic in postQuestion (同一タイトル5分制限)

### Data Layer for User Story 1

- [ ] T028 [P] [US1] Implement QuestionRepositoryImpl in lib/features/community/data/repositories/question_repository_impl.dart (Firestore CRUD)
- [ ] T029 [P] [US1] Create question_provider.dart in lib/features/community/providers/ (StateNotifierProvider for question list state)

### Presentation Layer for User Story 1

- [ ] T030 [US1] Create QuestionListScreen in lib/features/community/presentation/screens/question_list_screen.dart
- [ ] T031 [P] [US1] Create QuestionDetailScreen in lib/features/community/presentation/screens/question_detail_screen.dart
- [ ] T032 [P] [US1] Create QuestionPostScreen in lib/features/community/presentation/screens/question_post_screen.dart
- [ ] T033 [P] [US1] Create QuestionListItem widget in lib/features/community/presentation/widgets/question_list_item.dart
- [ ] T034 [US1] Add question post route to lib/core/router/app_router.dart
- [ ] T035 [US1] Add Firebase Analytics events (question_posted, question_viewed) in question screens

### Error Handling for User Story 1

- [ ] T036 [US1] Add DevCoin insufficient balance dialog in QuestionPostScreen
- [ ] T037 [P] [US1] Add duplicate post error handling in QuestionPostScreen
- [ ] T038 [P] [US1] Add offline cache strategy with sqflite in lib/features/community/data/local/question_cache.dart

**Checkpoint**: User Story 1完成 - 質問投稿・閲覧機能が独立して動作し、テスト可能

---

## Phase 3: User Story 2 - 質問への回答と報酬獲得 (Priority: P1) 🎯 MVP

**Goal**: 開発者が他の開発者の技術的質問に回答することで、5 DevCoinを獲得し、コミュニティに貢献できる。回答が質問者に採用されると追加15 DevCoinの報酬を得られる。

**Independent Test**: ユーザーが既存の質問に回答を投稿し、5 DevCoinを獲得できることを確認。質問者がベストアンサーを選択すると回答者に追加15 DevCoinが付与されることを確認。

**Constitution Check**:
- ✅ Principle I（回答投稿で即座に5 DevCoin付与、即時フィードバック）
- ✅ Principle II（Q&A双方向性確立、US1と組み合わせて完全なMVP）

### Tests for User Story 2

- [ ] T039 [P] [US2] Integration test for answer post & reward in test/integration/community/answer_post_test.dart
- [ ] T040 [P] [US2] Integration test for best answer selection in test/integration/community/best_answer_test.dart
- [ ] T041 [P] [US2] Widget test for AnswerItem in test/widget/community/answer_item_test.dart

### Cloud Functions for User Story 2

- [ ] T042 [P] [US2] Implement postAnswer Cloud Function in functions/src/community/post_answer.ts (トランザクション: 回答作成→5 DevCoin付与→answerCountインクリメント)
- [ ] T043 [P] [US2] Implement selectBestAnswer Cloud Function in functions/src/community/select_best_answer.ts (トランザクション: isBestAnswer=true→bestAnswerId更新→15 DevCoin付与)
- [ ] T044 [P] [US2] Implement evaluateAnswer Cloud Function in functions/src/community/evaluate_answer.ts (評価記録作成→helpfulCount/notHelpfulCountインクリメント)

### Data Layer for User Story 2

- [ ] T045 [P] [US2] Implement AnswerRepositoryImpl in lib/features/community/data/repositories/answer_repository_impl.dart
- [ ] T046 [P] [US2] Create answer_provider.dart in lib/features/community/providers/ (answer list state管理)

### Presentation Layer for User Story 2

- [ ] T047 [US2] Add answer list to QuestionDetailScreen (既存のlib/features/community/presentation/screens/question_detail_screen.dart更新)
- [ ] T048 [P] [US2] Create AnswerPostBottomSheet in lib/features/community/presentation/widgets/answer_post_bottom_sheet.dart
- [ ] T049 [P] [US2] Create AnswerItem widget in lib/features/community/presentation/widgets/answer_item.dart (評価ボタン含む)
- [ ] T050 [P] [US2] Create BestAnswerBadge widget in lib/features/community/presentation/widgets/best_answer_badge.dart
- [ ] T051 [US2] Add Firebase Analytics events (answer_posted, best_answer_selected, answer_evaluated)

### Notifications for User Story 2

- [ ] T052 [US2] Implement push notification for best answer selection in functions/src/community/notifications/best_answer_notification.ts (Firebase Cloud Messaging)

**Checkpoint**: User Story 2完成 - 回答投稿・ベストアンサー選択機能が動作、US1と組み合わせて完全なQ&Aプラットフォーム完成

---

## Phase 4: User Story 3 - ハッシュタグタイムラインの閲覧 (Priority: P2)

**Goal**: 開発者は特定のハッシュタグ（例：#個人開発チャレンジ）が付いた外部SNS（X/Threads/Instagram）の投稿をアプリ内で閲覧し、他の開発者の進捗や活動を知ることができる。

**Independent Test**: 指定ハッシュタグの投稿がアプリ内タイムラインに統合表示されることを確認。

**Constitution Check**:
- ✅ Principle I（孤独感解消、他者の進捗を見てモチベーション維持）
- ✅ Principle VII（外部API依存の実現性検証PoC必須、NOTE-001）

### PoC Validation (実装前に実施)

- [ ] T053 [US3] PoC: X API v2ハッシュタグ検索テスト in functions/src/community/poc/twitter_hashtag_test.ts
- [ ] T054 [US3] PoC: Threads API可用性確認（最新仕様チェック）
- [ ] T055 [US3] PoC: Instagram Graph API投稿取得テスト in functions/src/community/poc/instagram_hashtag_test.ts

### Tests for User Story 3 (PoC成功後)

- [ ] T056 [P] [US3] Integration test for hashtag timeline in test/integration/community/hashtag_timeline_test.dart
- [ ] T057 [P] [US3] Widget test for HashtagPostItem in test/widget/community/hashtag_post_item_test.dart

### Cloud Functions for User Story 3

- [ ] T058 [P] [US3] Implement SNSRateLimiter class in functions/src/community/sns/rate_limiter.ts (api_rate_limitsコレクション管理)
- [ ] T059 [US3] Implement fetchHashtagTimeline Cloud Function in functions/src/community/fetch_hashtag_timeline.ts (キャッシュ優先、3 SNS統合)
- [ ] T060 [P] [US3] Implement Twitter API client in functions/src/community/sns/twitter_client.ts (twitter-api-v2使用)
- [ ] T061 [P] [US3] Implement Threads API client in functions/src/community/sns/threads_client.ts (REST直接呼び出し)
- [ ] T062 [P] [US3] Implement Instagram API client in functions/src/community/sns/instagram_client.ts (facebook-nodejs-business-sdk使用)
- [ ] T063 [US3] Implement scheduledCleanupHashtagCache in functions/src/community/scheduled/cleanup_hashtag_cache.ts (5分ごと実行)

### Data Layer for User Story 3

- [ ] T064 [P] [US3] Implement SnsRepositoryImpl in lib/features/community/data/repositories/sns_repository_impl.dart
- [ ] T065 [P] [US3] Create hashtag_timeline_provider.dart in lib/features/community/providers/ (timeline state管理)

### Presentation Layer for User Story 3

- [ ] T066 [US3] Create HashtagTimelineScreen in lib/features/community/presentation/screens/hashtag_timeline_screen.dart
- [ ] T067 [P] [US3] Create HashtagPostItem widget in lib/features/community/presentation/widgets/hashtag_post_item.dart (SNS種別アイコン表示)
- [ ] T068 [P] [US3] Create SNSProviderBadge widget in lib/features/community/presentation/widgets/sns_provider_badge.dart (X/Threads/Instagramアイコン)
- [ ] T069 [US3] Add hashtag timeline route to lib/core/router/app_router.dart
- [ ] T070 [US3] Add Firebase Analytics events (hashtag_timeline_viewed, hashtag_post_clicked)

### Error Handling for User Story 3

- [ ] T071 [P] [US3] Add rate limit notification banner in HashtagTimelineScreen
- [ ] T072 [P] [US3] Add SNS API error handling (障害中SNSの通知バナー表示)

**Checkpoint**: User Story 3完成 - ハッシュタグタイムライン閲覧機能が動作、キャッシュ・レート制限管理完備

---

## Phase 5: User Story 4 - アプリ内からのSNSインタラクション (Priority: P2)

**Goal**: 開発者はアプリ内のタイムラインから直接、外部SNSの投稿にいいね・リツイート・コメントができる。アプリを離れることなくコミュニティと交流できる。

**Independent Test**: アプリ内からSNS投稿にいいねを実行し、実際のSNSに反映されることを確認。

**Constitution Check**:
- ✅ Principle I（能動的な交流で孤独感解消を強化）
- ✅ Principle VII（健全なコミュニティ育成）

### Tests for User Story 4

- [ ] T073 [P] [US4] Integration test for SNS OAuth connection in test/integration/community/sns_connection_test.dart
- [ ] T074 [P] [US4] Integration test for SNS action (like/retweet/comment) in test/integration/community/sns_action_test.dart

### Cloud Functions for User Story 4

- [ ] T075 [US4] Implement connectSNS Cloud Function in functions/src/community/connect_sns.ts (OAuth 2.0 PKCEフロー、トークン暗号化保存)
- [ ] T076 [US4] Implement performSNSAction Cloud Function in functions/src/community/perform_sns_action.ts (like/retweet/comment実行)
- [ ] T077 [P] [US4] Add token refresh logic in functions/src/community/sns/token_refresher.ts (有効期限前に自動更新)

### Data Layer for User Story 4

- [ ] T078 [P] [US4] Update SnsRepositoryImpl with OAuth connection methods
- [ ] T079 [P] [US4] Create sns_connection_provider.dart in lib/features/community/providers/ (連携状態管理)

### Presentation Layer for User Story 4

- [ ] T080 [US4] Create SNSConnectionScreen in lib/features/community/presentation/screens/sns_connection_screen.dart (OAuth認証フロー、flutter_appauth使用)
- [ ] T081 [P] [US4] Add SNS action buttons to HashtagPostItem (いいね・リツイート・コメント)
- [ ] T082 [P] [US4] Create SNSActionDialog in lib/features/community/presentation/widgets/sns_action_dialog.dart (コメント入力)
- [ ] T083 [US4] Add SNS connection prompt dialog for unauthenticated actions
- [ ] T084 [US4] Add Firebase Analytics events (sns_connected, sns_action_performed)

**Checkpoint**: User Story 4完成 - SNS連携・アクション実行機能が動作、US3と組み合わせて双方向SNS統合完成

---

## Phase 6: User Story 5 - 質問・回答の検索とフィルタリング (Priority: P2)

**Goal**: 開発者は過去の質問・回答をキーワード検索やカテゴリフィルタで絞り込み、自分の課題に関連するナレッジを素早く見つけられる。

**Independent Test**: キーワード検索で関連質問が2秒以内に表示されることを確認（10,000質問データ）。

**Constitution Check**:
- ✅ Principle I（知識不足解決を効率化）
- ✅ NFR-001（10,000質問で2秒以内レスポンス）

### Tests for User Story 5

- [ ] T085 [P] [US5] Integration test for keyword search in test/integration/community/question_search_test.dart
- [ ] T086 [P] [US5] Performance test for search with 10,000 questions (2秒以内確認)

### Cloud Functions for User Story 5

- [ ] T087 [P] [US5] Implement searchQuestions Cloud Function in functions/src/community/search_questions.ts (Firestore複合インデックス活用、ページネーション)

### Presentation Layer for User Story 5

- [ ] T088 [US5] Create QuestionSearchScreen in lib/features/community/presentation/screens/question_search_screen.dart
- [ ] T089 [P] [US5] Create CategoryFilterChips in lib/features/community/presentation/widgets/category_filter_chips.dart
- [ ] T090 [P] [US5] Create SortDropdown in lib/features/community/presentation/widgets/sort_dropdown.dart (最新/回答数/評価順)
- [ ] T091 [US5] Add search bar to QuestionListScreen
- [ ] T092 [US5] Add Firebase Analytics events (question_searched, filter_applied, sort_changed)

**Checkpoint**: User Story 5完成 - 検索・フィルタリング機能が動作、Q&Aプラットフォームのナレッジベース価値向上

---

## Phase 7: User Story 6 - コメント・応援機能 (Priority: P3)

**Goal**: 開発者は他の開発者の質問や回答にコメントや応援メッセージを送り、コミュニティで励まし合える。テンプレート化されたコメントで気軽に参加できる。

**Independent Test**: 質問や回答にコメントを投稿し、他のユーザーが閲覧できることを確認。

**Constitution Check**:
- ✅ Principle I（コミュニティの温かみ、孤独感解消）
- ✅ Principle VII（健全なコミュニティ育成）

### Tests for User Story 6

- [ ] T093 [P] [US6] Integration test for comment post in test/integration/community/comment_post_test.dart
- [ ] T094 [P] [US6] Widget test for CommentItem in test/widget/community/comment_item_test.dart

### Cloud Functions for User Story 6

- [ ] T095 [P] [US6] Implement postComment Cloud Function in functions/src/community/post_comment.ts (テンプレート展開、通知送信)

### Data Layer for User Story 6

- [ ] T096 [P] [US6] Create CommentRepository interface in lib/features/community/domain/repositories/comment_repository.dart
- [ ] T097 [P] [US6] Implement CommentRepositoryImpl in lib/features/community/data/repositories/comment_repository_impl.dart
- [ ] T098 [P] [US6] Create comment_provider.dart in lib/features/community/providers/

### Presentation Layer for User Story 6

- [ ] T099 [US6] Add comment section to QuestionDetailScreen
- [ ] T100 [P] [US6] Create CommentBottomSheet in lib/features/community/presentation/widgets/comment_bottom_sheet.dart (テンプレート選択UI)
- [ ] T101 [P] [US6] Create CommentItem widget in lib/features/community/presentation/widgets/comment_item.dart
- [ ] T102 [P] [US6] Create EncouragementButton in lib/features/community/presentation/widgets/encouragement_button.dart (応援ボタン)
- [ ] T103 [US6] Add Firebase Analytics events (comment_posted, encouragement_sent)

**Checkpoint**: User Story 6完成 - コメント・応援機能が動作、コミュニティの温かみ醸成

---

## Phase 8: User Story 7 - プレミアムプラン導入 (Priority: P3)

**Goal**: 開発者は月額680円のプレミアムプランに加入することで、AI機能無制限・広告なし・毎月DevCoinボーナスなどの特典を得られる。

**Independent Test**: プレミアムプランに加入し、広告が非表示になり毎月200 DevCoinが付与されることを確認。

**Constitution Check**:
- ✅ Principle V（マネタイズ基盤確立、サービス持続可能性）
- ✅ Legal & Compliance（App Store/Google Play課金API使用、資金決済法対応）

### Tests for User Story 7 (Sandbox環境)

- [ ] T104 [P] [US7] Integration test for premium purchase (Sandbox) in test/integration/community/premium_purchase_test.dart

### Cloud Functions for User Story 7

- [ ] T105 [US7] Implement verifyPremiumPurchase Cloud Function in functions/src/community/verify_premium_purchase.ts (App Store/Google Playレシート検証、200 DevCoin付与)
- [ ] T106 [P] [US7] Implement webhook/appleSubscription endpoint in functions/src/community/webhooks/apple_subscription.ts (App Store Server Notifications V2)
- [ ] T107 [P] [US7] Implement webhook/googleSubscription endpoint in functions/src/community/webhooks/google_subscription.ts (Google Real-time Developer Notifications、Cloud Pub/Sub)
- [ ] T108 [US7] Implement scheduledCheckPremiumPaymentFailed in functions/src/community/scheduled/check_premium_payment.ts (毎日午前0時、7日猶予期間チェック)

### Data Layer for User Story 7

- [ ] T109 [P] [US7] Create SubscriptionRepository interface in lib/features/community/domain/repositories/subscription_repository.dart
- [ ] T110 [P] [US7] Implement SubscriptionRepositoryImpl in lib/features/community/data/repositories/subscription_repository_impl.dart (in_app_purchase統合)
- [ ] T111 [P] [US7] Create subscription_provider.dart in lib/features/community/providers/

### Presentation Layer for User Story 7

- [ ] T112 [US7] Create PremiumPlanScreen in lib/features/community/presentation/screens/premium_plan_screen.dart (特典説明、購入ボタン)
- [ ] T113 [P] [US7] Create PremiumBadge widget in lib/features/community/presentation/widgets/premium_badge.dart (プレミアム会員アイコン)
- [ ] T114 [US7] Add premium plan route to lib/core/router/app_router.dart
- [ ] T115 [US7] Add premium benefits display (広告非表示、AI無制限) in relevant screens
- [ ] T116 [US7] Add Firebase Analytics events (premium_viewed, premium_purchased, premium_cancelled)

### App Store / Google Play Setup

- [ ] T117 [US7] Register premium_monthly_680 product in App Store Connect
- [ ] T118 [P] [US7] Register premium_monthly_680 subscription in Google Play Console
- [ ] T119 [P] [US7] Configure App Store Server Notifications webhook URL in App Store Connect

**Checkpoint**: User Story 7完成 - プレミアムプラン購入・管理機能が動作、マネタイズ基盤確立

---

## Phase 9: Moderation & Scheduled Tasks

**Purpose**: コンテンツモデレーション機能と定期実行タスクを実装

- [ ] T120 [P] Create ContentReport model in lib/features/community/domain/models/content_report.dart
- [ ] T121 [P] Implement reportContent Cloud Function in functions/src/community/report_content.ts
- [ ] T122 [P] Create content report UI in lib/features/community/presentation/widgets/report_button.dart
- [ ] T123 Implement scheduledDeleteExpiredContent in functions/src/community/scheduled/delete_expired_content.ts (毎日午前3時、ソフト削除から7日経過コンテンツ完全削除)
- [ ] T124 Deploy scheduled functions with firebase deploy --only functions

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: 全ユーザーストーリーに影響する改善

- [ ] T125 [P] Add loading skeletons to all list screens (question_list, answer_list, hashtag_timeline)
- [ ] T126 [P] Implement error boundary widgets in lib/shared/widgets/error_boundary.dart
- [ ] T127 [P] Add pull-to-refresh to all list screens
- [ ] T128 [P] Optimize image loading with cached_network_image for all avatar/media displays
- [ ] T129 Add Firebase Performance Monitoring to critical screens (question_list, question_detail, hashtag_timeline)
- [ ] T130 [P] Update 利用規約 with SNS連携・コンテンツ報告条項 (法務レビュー必須)
- [ ] T131 [P] Update プライバシーポリシー with SNSトークン保管・外部APIデータ取得記載 (法務レビュー必須)
- [ ] T132 Run quickstart.md validation (全フロー動作確認)
- [ ] T133 Performance optimization: Firestore query optimization review
- [ ] T134 Security hardening: Review all Firestore security rules
- [ ] T135 Documentation: Update README.md with Phase 2 features

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 0)**: 依存なし - 即座に開始可能
- **Foundational (Phase 1)**: Setup完了に依存 - 全ユーザーストーリーをブロック
- **User Stories (Phase 2-8)**: 全てFoundational完了に依存
  - US1とUS2は相互依存（US2はUS1の質問詳細画面を拡張）
  - US3とUS4は相互依存（US4はUS3のタイムライン画面を拡張）
  - US5はUS1に依存（検索対象は質問）
  - US6はUS1とUS2に依存（コメント対象は質問と回答）
  - US7は独立（他ストーリーとの依存なし）
- **Moderation (Phase 9)**: US1, US2, US6完了後に開始推奨
- **Polish (Phase 10)**: 全実装完了後

### User Story Dependencies

```
Foundational (Phase 1) → 全ストーリーの前提条件
├─ US1 (質問投稿・閲覧) → MVP最優先
├─ US2 (回答・報酬) → US1に依存（質問詳細画面拡張）
├─ US3 (ハッシュタグタイムライン) → 独立実装可能、PoC検証必須
├─ US4 (SNSインタラクション) → US3に依存（タイムライン画面拡張）
├─ US5 (検索・フィルタ) → US1に依存（質問検索）
├─ US6 (コメント・応援) → US1, US2に依存（コメント対象）
└─ US7 (プレミアムプラン) → 独立実装可能
```

### Within Each User Story

1. Tests → Models → Cloud Functions → Data Layer → Presentation Layer
2. PoC検証（US3のみ）→ 実装
3. 各ストーリー完了後にCheckpoint検証

### Parallel Opportunities

- **Setup (Phase 0)**: T002, T003, T004, T005, T006 並行実行可能
- **Foundational (Phase 1)**: T009-T014 (models), T019-T021 (widgets) 並行実行可能
- **US1 Tests**: T023, T024, T025 並行実行可能
- **US1 Functions**: T026, T027 並行実行可能
- **US1 Data/Providers**: T028, T029 並行実行可能
- **US1 UI Components**: T031, T032, T033 並行実行可能
- **US2 Tests**: T039, T040, T041 並行実行可能
- **US2 Functions**: T042, T043, T044 並行実行可能
- **US3 PoC**: T053, T055 並行実行可能（T054は手動確認）
- **US3 Functions**: T058, T060, T061, T062 並行実行可能
- **US7 Webhooks**: T106, T107 並行実行可能
- **Polish**: T125-T128, T130-T131 並行実行可能

---

## Parallel Example: User Story 1

```bash
# 並行実行グループ1: Tests
T023: Integration test for question post flow
T024: Integration test for question list & detail view
T025: Widget test for QuestionListItem

# 並行実行グループ2: Cloud Functions
T026: Implement postQuestion Cloud Function
T027: Add duplicate question prevention logic

# 並行実行グループ3: Data Layer
T028: Implement QuestionRepositoryImpl
T029: Create question_provider

# 並行実行グループ4: UI Components
T031: Create QuestionDetailScreen
T032: Create QuestionPostScreen
T033: Create QuestionListItem widget
```

---

## Implementation Strategy

### MVP First (User Story 1 + 2 Only)

1. Complete Phase 0: Setup (T001-T007)
2. Complete Phase 1: Foundational (T008-T022) - **CRITICAL**
3. Complete Phase 2: User Story 1 (T023-T038)
4. Complete Phase 3: User Story 2 (T039-T052)
5. **STOP and VALIDATE**: Q&Aプラットフォーム基本機能を独立テスト
6. Deploy/Demo if ready (Firebase Hosting + Functions)

**MVP Scope**: US1(質問投稿・閲覧) + US2(回答・報酬) = 完全なQ&Aプラットフォーム

### Incremental Delivery

1. Setup + Foundational → 基盤完成
2. Add US1 + US2 → Q&Aプラットフォーム完成 → Deploy/Demo (MVP!)
3. Add US3 + US4 → SNS統合完成 → Deploy/Demo
4. Add US5 → 検索機能追加 → Deploy/Demo
5. Add US6 → コミュニティ温かみ向上 → Deploy/Demo
6. Add US7 → マネタイズ基盤確立 → Deploy/Demo
7. 各ストーリーが独立して価値を追加、既存機能を破壊しない

### Parallel Team Strategy

複数開発者がいる場合:

1. チーム全員でSetup + Foundational完了
2. Foundational完了後、並行実装:
   - Developer A: US1 (質問投稿・閲覧)
   - Developer B: US2 (回答・報酬)
   - Developer C: US3 PoC検証 → US3実装
3. US1+US2完了後:
   - Developer A: US5 (検索)
   - Developer B: US6 (コメント)
   - Developer C: US4 (SNSアクション) + US7 (プレミアム)
4. 各ストーリーは独立して完成・統合可能

---

## Task Summary

**Total Tasks**: 135 tasks
- Phase 0 (Setup): 7 tasks
- Phase 1 (Foundational): 15 tasks (CRITICAL - blocks all stories)
- Phase 2 (US1): 16 tasks
- Phase 3 (US2): 14 tasks
- Phase 4 (US3): 20 tasks (PoC 3 + Implementation 17)
- Phase 5 (US4): 12 tasks
- Phase 6 (US5): 8 tasks
- Phase 7 (US6): 11 tasks
- Phase 8 (US7): 16 tasks
- Phase 9 (Moderation): 5 tasks
- Phase 10 (Polish): 11 tasks

**Parallel Opportunities**: 約60% of tasks marked [P]

**Independent Test Criteria**:
- US1: 質問投稿・閲覧単独動作
- US2: 回答投稿・報酬単独動作、US1と統合してQ&A完成
- US3: ハッシュタグタイムライン単独動作
- US4: SNSアクション単独動作、US3と統合してSNS双方向完成
- US5: 検索機能単独動作、US1と統合して検索可能Q&A完成
- US6: コメント機能単独動作、US1/US2と統合
- US7: プレミアム購入単独動作、全機能と統合で特典適用

**Suggested MVP Scope**: US1 + US2 (Q&Aプラットフォーム基本機能)

---

## Format Validation

✅ All tasks follow checklist format: `- [ ] [ID] [P?] [Story?] Description`
✅ All tasks include file paths or specific implementation details
✅ Story labels correctly map to user stories (US1-US7)
✅ Parallel markers ([P]) correctly identify independent tasks
✅ Task IDs are sequential (T001-T135)
✅ Dependencies clearly documented
✅ Independent test criteria defined for each story

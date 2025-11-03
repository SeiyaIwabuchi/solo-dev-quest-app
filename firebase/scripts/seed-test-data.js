/**
 * Firestore Emulatorにテストデータを投入するスクリプト
 * 
 * 使用方法:
 * 1. Firebase Emulatorを起動: firebase emulators:start
 * 2. 別のターミナルでこのスクリプトを実行: cd functions && node ../scripts/seed-test-data.js
 */

// functionsディレクトリのnode_modulesから読み込む
const path = require('path');
const functionsDir = path.join(__dirname, '../functions');
const admin = require(path.join(functionsDir, 'node_modules/firebase-admin'));

// Emulatorに接続
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';

admin.initializeApp({
  projectId: 'solo-dev-quest-app',
});

const db = admin.firestore();

// テストユーザーIDを環境変数または引数から取得
const TEST_USER_ID = process.env.TEST_USER_ID || process.argv[2] || 'test-user-001';

console.log(`📝 使用するユーザーID: ${TEST_USER_ID}\n`);

/**
 * プロジェクトとタスクを生成
 */
async function seedTestData() {
  console.log('🌱 テストデータの生成を開始します...\n');

  try {
    // 既存のテストデータをクリア
    console.log('📝 既存のテストデータをクリアしています...');
    await clearExistingData();
    console.log('✅ クリア完了\n');

    // プロジェクトを作成
    console.log('📂 プロジェクトを作成しています...');
    const projectIds = [];
    
    // プロジェクト1: 少数のタスク（10個）
    const project1Id = await createProject({
      name: '🚀 スタートアッププロジェクト',
      description: 'テスト用の小規模プロジェクト（10タスク）',
      taskCount: 10,
      completedRatio: 0.5,
    });
    projectIds.push(project1Id);
    console.log(`  ✓ プロジェクト1作成完了: ${project1Id}`);

    // プロジェクト2: 中規模のタスク（50個）
    const project2Id = await createProject({
      name: '💼 中規模開発プロジェクト',
      description: 'テスト用の中規模プロジェクト（50タスク）',
      taskCount: 50,
      completedRatio: 0.3,
    });
    projectIds.push(project2Id);
    console.log(`  ✓ プロジェクト2作成完了: ${project2Id}`);

    // プロジェクト3: 大規模のタスク（200個）
    const project3Id = await createProject({
      name: '🏢 大規模エンタープライズプロジェクト',
      description: 'テスト用の大規模プロジェクト（200タスク）- 無限スクロールテスト用',
      taskCount: 200,
      completedRatio: 0.2,
    });
    projectIds.push(project3Id);
    console.log(`  ✓ プロジェクト3作成完了: ${project3Id}`);

    // プロジェクト4: 完了済みプロジェクト（20個すべて完了）
    const project4Id = await createProject({
      name: '✅ 完了済みプロジェクト',
      description: 'すべてのタスクが完了しているプロジェクト',
      taskCount: 20,
      completedRatio: 1.0,
    });
    projectIds.push(project4Id);
    console.log(`  ✓ プロジェクト4作成完了: ${project4Id}`);

    // プロジェクト5: 期限切れタスクが多いプロジェクト（30個）
    const project5Id = await createProject({
      name: '⚠️ 期限切れタスク多数',
      description: '期限切れタスクが多いプロジェクト',
      taskCount: 30,
      completedRatio: 0.1,
      overdueRatio: 0.6,
    });
    projectIds.push(project5Id);
    console.log(`  ✓ プロジェクト5作成完了: ${project5Id}`);

    console.log('\n✨ テストデータの生成が完了しました！\n');
    console.log('📊 サマリー:');
    console.log(`  - プロジェクト数: ${projectIds.length}`);
    console.log(`  - 総タスク数: 310個`);
    console.log('\n🔗 Firebase Emulator UI: http://localhost:4000');
    console.log('');

  } catch (error) {
    console.error('❌ エラーが発生しました:', error);
    process.exit(1);
  }

  process.exit(0);
}

/**
 * 既存のテストデータをクリア
 */
async function clearExistingData() {
  const batch = db.batch();

  // プロジェクトを削除
  const projects = await db.collection('projects')
    .where('userId', '==', TEST_USER_ID)
    .get();
  projects.docs.forEach(doc => batch.delete(doc.ref));

  // タスクを削除
  const tasks = await db.collection('tasks')
    .where('userId', '==', TEST_USER_ID)
    .get();
  tasks.docs.forEach(doc => batch.delete(doc.ref));

  await batch.commit();
}

/**
 * プロジェクトとそのタスクを作成
 */
async function createProject({
  name,
  description,
  taskCount,
  completedRatio = 0.3,
  overdueRatio = 0.2,
}) {
  const now = new Date();
  const projectRef = db.collection('projects').doc();
  
  const projectData = {
    id: projectRef.id,
    userId: TEST_USER_ID,
    name,
    description,
    createdAt: admin.firestore.Timestamp.fromDate(now),
    updatedAt: admin.firestore.Timestamp.fromDate(now),
  };

  await projectRef.set(projectData);

  // タスクを作成
  console.log(`    → ${taskCount}個のタスクを作成中...`);
  await createTasks(projectRef.id, taskCount, completedRatio, overdueRatio);

  return projectRef.id;
}

/**
 * タスクを一括作成
 */
async function createTasks(projectId, count, completedRatio, overdueRatio) {
  const tasks = [];
  const completedCount = Math.floor(count * completedRatio);
  const overdueCount = Math.floor(count * overdueRatio);

  for (let i = 0; i < count; i++) {
    const now = new Date();
    const isCompleted = i < completedCount;
    const isOverdue = !isCompleted && i < (completedCount + overdueCount);

    // 期限を設定
    let dueDate = null;
    if (isOverdue) {
      // 過去の日付（1-30日前）
      const daysAgo = Math.floor(Math.random() * 30) + 1;
      dueDate = new Date(now.getTime() - daysAgo * 24 * 60 * 60 * 1000);
    } else {
      // 未来の日付（1-60日後）
      const daysLater = Math.floor(Math.random() * 60) + 1;
      dueDate = new Date(now.getTime() + daysLater * 24 * 60 * 60 * 1000);
    }

    // 作成日時を設定（古いものから順に）
    const createdAt = new Date(now.getTime() - (count - i) * 60 * 1000);

    const taskRef = db.collection('tasks').doc();
    const taskData = {
      id: taskRef.id,
      projectId,
      userId: TEST_USER_ID,
      name: `タスク ${i + 1}: ${generateTaskName(i)}`,
      description: generateTaskDescription(i, isCompleted, isOverdue),
      dueDate: admin.firestore.Timestamp.fromDate(dueDate),
      isCompleted,
      createdAt: admin.firestore.Timestamp.fromDate(createdAt),
      updatedAt: admin.firestore.Timestamp.fromDate(now),
      completedAt: isCompleted ? admin.firestore.Timestamp.fromDate(now) : null,
    };

    tasks.push(taskRef.set(taskData));
  }

  // バッチ処理で一括書き込み（500件ずつ）
  const batchSize = 500;
  for (let i = 0; i < tasks.length; i += batchSize) {
    const batch = tasks.slice(i, i + batchSize);
    await Promise.all(batch);
  }
}

/**
 * タスク名を生成
 */
function generateTaskName(index) {
  const names = [
    'API設計とドキュメント作成',
    'データベーススキーマ設計',
    'フロントエンドコンポーネント実装',
    'バックエンドエンドポイント実装',
    '単体テスト作成',
    '統合テスト実装',
    'パフォーマンス最適化',
    'セキュリティレビュー',
    'コードレビュー対応',
    'ドキュメント更新',
    'バグ修正',
    'リファクタリング',
    'CI/CDパイプライン設定',
    'デプロイ準備',
    'ユーザーフィードバック対応',
  ];

  return names[index % names.length];
}

/**
 * タスク説明を生成
 */
function generateTaskDescription(index, isCompleted, isOverdue) {
  const descriptions = [
    'REST APIエンドポイントを設計し、OpenAPI仕様書を作成する。認証、エラーハンドリング、レート制限を考慮。',
    'PostgreSQLのテーブル設計を行い、マイグレーションスクリプトを作成。正規化とインデックス戦略を検討。',
    'Reactコンポーネントを実装し、TypeScriptの型安全性を確保。再利用可能な設計を心がける。',
    'Node.js + Expressでバックエンドロジックを実装。ビジネスロジックとデータアクセス層を分離。',
    'Jestを使用した単体テストを作成。カバレッジ80%以上を目指す。',
    'Playwrightを使用したE2Eテストを実装。主要なユーザーフローをカバー。',
    'クエリの最適化、キャッシュ戦略の導入、バンドルサイズの削減を実施。',
    'OWASP Top 10に基づくセキュリティチェック。SQLインジェクション、XSS対策を確認。',
    'レビューコメントに対応し、コード品質を向上。指摘事項をすべて解決。',
    'READMEとAPIドキュメントを最新の実装に合わせて更新。使用例を追加。',
    'バグトラッカーの課題を修正。再現手順を確認し、テストケースを追加。',
    'コードの可読性と保守性を向上。命名規則の統一、重複コードの削減。',
    'GitHub Actionsでテスト、ビルド、デプロイの自動化パイプラインを構築。',
    '本番環境へのデプロイ準備。環境変数の設定、ロールバック手順の確認。',
    'ユーザーからのフィードバックを分析し、改善案を実装。UXの向上を図る。',
  ];

  let desc = descriptions[index % descriptions.length];
  
  if (isCompleted) {
    desc += '\n\n✅ 完了済み';
  } else if (isOverdue) {
    desc += '\n\n⚠️ 期限切れ - 早急な対応が必要';
  }

  return desc;
}

// スクリプトを実行
seedTestData();

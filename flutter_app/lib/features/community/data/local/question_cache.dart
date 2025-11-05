// T038: QuestionCache - オフラインキャッシュ戦略（過去24時間の質問をsqfliteに保存）
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/models/question.dart';

/// 質問のオフラインキャッシュを管理するクラス
/// 
/// 機能:
/// - 質問をsqfliteに保存（過去24時間の閲覧履歴）
/// - オフライン時にキャッシュから質問を取得
/// - 古いキャッシュ（24時間以上前）を自動削除
/// - NFR-007: オフライン時でも90%以上の閲覧リクエストに応答
class QuestionCache {
  static const String _databaseName = 'community_cache.db';
  static const int _databaseVersion = 1;
  static const String _tableQuestions = 'cached_questions';
  
  static Database? _database;

  /// データベースインスタンスを取得（シングルトン）
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// データベースを初期化
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  /// テーブルを作成
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableQuestions (
        question_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        code_example TEXT,
        category_tag TEXT NOT NULL,
        author_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        author_avatar_url TEXT,
        answer_count INTEGER NOT NULL DEFAULT 0,
        view_count INTEGER NOT NULL DEFAULT 0,
        evaluation_score INTEGER NOT NULL DEFAULT 0,
        best_answer_id TEXT,
        deletion_status TEXT NOT NULL DEFAULT 'normal',
        deletion_reason TEXT,
        scheduled_deletion_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        cached_at INTEGER NOT NULL
      )
    ''');

    // インデックス: cached_atでソートするため
    await db.execute('''
      CREATE INDEX idx_cached_at ON $_tableQuestions(cached_at DESC)
    ''');
  }

  /// 質問をキャッシュに保存（閲覧時に呼び出す）
  Future<void> cacheQuestion(Question question) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      _tableQuestions,
      {
        'question_id': question.questionId,
        'title': question.title,
        'body': question.body,
        'code_example': question.codeExample,
        'category_tag': question.categoryTag,
        'author_id': question.authorId,
        'author_name': question.authorName,
        'author_avatar_url': question.authorAvatarUrl,
        'answer_count': question.answerCount,
        'view_count': question.viewCount,
        'evaluation_score': question.evaluationScore,
        'best_answer_id': question.bestAnswerId,
        'deletion_status': question.deletionStatus,
        'deletion_reason': question.deletionReason,
        'scheduled_deletion_at': question.scheduledDeletionAt?.millisecondsSinceEpoch,
        'created_at': question.createdAt.millisecondsSinceEpoch,
        'updated_at': question.updatedAt?.millisecondsSinceEpoch,
        'cached_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// キャッシュから質問を取得（questionId指定）
  Future<Question?> getCachedQuestion(String questionId) async {
    final db = await database;
    
    final results = await db.query(
      _tableQuestions,
      where: 'question_id = ?',
      whereArgs: [questionId],
      limit: 1,
    );

    if (results.isEmpty) return null;

    return _questionFromMap(results.first);
  }

  /// キャッシュから質問一覧を取得（最新順、過去24時間のみ）
  /// 
  /// [limit] 取得件数（デフォルト: 20）
  /// [offset] オフセット（ページネーション用、デフォルト: 0）
  Future<List<Question>> getCachedQuestions({
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final twentyFourHoursAgo = now - (24 * 60 * 60 * 1000);

    final results = await db.query(
      _tableQuestions,
      where: 'cached_at > ?',
      whereArgs: [twentyFourHoursAgo],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => _questionFromMap(map)).toList();
  }

  /// カテゴリでフィルタリングしたキャッシュ質問一覧を取得
  Future<List<Question>> getCachedQuestionsByCategory(
    String categoryTag, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final twentyFourHoursAgo = now - (24 * 60 * 60 * 1000);

    final results = await db.query(
      _tableQuestions,
      where: 'cached_at > ? AND category_tag = ?',
      whereArgs: [twentyFourHoursAgo, categoryTag],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => _questionFromMap(map)).toList();
  }

  /// 古いキャッシュを削除（24時間以上前のデータ）
  Future<int> deleteOldCache() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final twentyFourHoursAgo = now - (24 * 60 * 60 * 1000);

    return await db.delete(
      _tableQuestions,
      where: 'cached_at < ?',
      whereArgs: [twentyFourHoursAgo],
    );
  }

  /// すべてのキャッシュをクリア（テスト用）
  Future<int> clearAllCache() async {
    final db = await database;
    return await db.delete(_tableQuestions);
  }

  /// キャッシュ統計を取得（デバッグ用）
  Future<Map<String, dynamic>> getCacheStats() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final twentyFourHoursAgo = now - (24 * 60 * 60 * 1000);

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableQuestions',
    );
    final recentResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableQuestions WHERE cached_at > ?',
      [twentyFourHoursAgo],
    );

    return {
      'total_cached_questions': totalResult.first['count'] as int,
      'recent_cached_questions': recentResult.first['count'] as int,
      'cache_retention_hours': 24,
    };
  }

  /// MapからQuestionオブジェクトを生成
  Question _questionFromMap(Map<String, dynamic> map) {
    return Question(
      questionId: map['question_id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      codeExample: map['code_example'] as String?,
      categoryTag: map['category_tag'] as String,
      authorId: map['author_id'] as String,
      authorName: map['author_name'] as String,
      authorAvatarUrl: map['author_avatar_url'] as String?,
      answerCount: map['answer_count'] as int,
      viewCount: map['view_count'] as int,
      evaluationScore: map['evaluation_score'] as int,
      bestAnswerId: map['best_answer_id'] as String?,
      deletionStatus: map['deletion_status'] as String,
      deletionReason: map['deletion_reason'] as String?,
      scheduledDeletionAt: map['scheduled_deletion_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduled_deletion_at'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
    );
  }

  /// データベースを閉じる（アプリ終了時）
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

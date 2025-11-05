import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/repositories/question_repository_impl.dart';
import '../domain/models/question.dart';
import '../domain/repositories/question_repository.dart';

part 'question_provider.freezed.dart';

/// 質問リポジトリプロバイダー
final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepositoryImpl();
});

/// 質問一覧の状態
@freezed
class QuestionListState with _$QuestionListState {
  const factory QuestionListState({
    @Default([]) List<Question> questions,
    @Default(false) bool isLoading,
    @Default(false) bool hasMore,
    String? error,
    String? lastQuestionId,
  }) = _QuestionListState;
}

/// 質問一覧StateNotifierProvider
class QuestionListNotifier extends StateNotifier<QuestionListState> {
  QuestionListNotifier(this._repository) : super(const QuestionListState());

  final QuestionRepository _repository;
  String? _categoryFilter;
  String _sortBy = 'latest';

  /// 質問一覧を初回読み込み
  Future<void> loadQuestions({
    String? categoryTag,
    String sortBy = 'latest',
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    _categoryFilter = categoryTag;
    _sortBy = sortBy;

    try {
      final questions = await _repository.getQuestions(
        categoryTag: categoryTag,
        sortBy: sortBy,
        limit: 20,
      );

      state = state.copyWith(
        questions: questions,
        isLoading: false,
        hasMore: questions.length >= 20,
        lastQuestionId: questions.isNotEmpty ? questions.last.questionId : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 質問一覧をさらに読み込み（ページネーション）
  Future<void> loadMoreQuestions() async {
    if (state.isLoading || !state.hasMore || state.lastQuestionId == null) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final newQuestions = await _repository.getQuestions(
        categoryTag: _categoryFilter,
        sortBy: _sortBy,
        limit: 20,
        startAfter: state.lastQuestionId,
      );

      state = state.copyWith(
        questions: [...state.questions, ...newQuestions],
        isLoading: false,
        hasMore: newQuestions.length >= 20,
        lastQuestionId:
            newQuestions.isNotEmpty ? newQuestions.last.questionId : state.lastQuestionId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 質問一覧をリフレッシュ
  Future<void> refresh() async {
    state = const QuestionListState();
    await loadQuestions(
      categoryTag: _categoryFilter,
      sortBy: _sortBy,
    );
  }

  /// カテゴリフィルターを変更
  Future<void> filterByCategory(String? categoryTag) async {
    if (_categoryFilter == categoryTag) return;
    state = const QuestionListState();
    await loadQuestions(categoryTag: categoryTag, sortBy: _sortBy);
  }

  /// ソート順を変更
  Future<void> changeSortBy(String sortBy) async {
    if (_sortBy == sortBy) return;
    state = const QuestionListState();
    await loadQuestions(categoryTag: _categoryFilter, sortBy: sortBy);
  }
}

/// 質問一覧プロバイダー
final questionListProvider =
    StateNotifierProvider<QuestionListNotifier, QuestionListState>((ref) {
  final repository = ref.watch(questionRepositoryProvider);
  return QuestionListNotifier(repository);
});

/// 特定の質問をリアルタイムで監視するプロバイダー
final questionStreamProvider =
    StreamProvider.family<Question?, String>((ref, questionId) {
  final repository = ref.watch(questionRepositoryProvider);
  return repository.watchQuestion(questionId);
});

/// 質問詳細プロバイダー（一度だけ取得）
final questionDetailProvider =
    FutureProvider.family<Question?, String>((ref, questionId) async {
  final repository = ref.watch(questionRepositoryProvider);
  return repository.getQuestion(questionId);
});

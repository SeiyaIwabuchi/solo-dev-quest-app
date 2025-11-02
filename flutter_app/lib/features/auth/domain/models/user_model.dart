import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// ユーザープロファイルモデル
/// Firebase AuthenticationとCloud Firestoreで管理されるユーザー情報
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    /// Firebase AuthのUID（一意識別子）
    required String uid,
    
    /// メールアドレス
    required String email,
    
    /// 表示名（Googleサインイン時に設定される場合がある）
    String? displayName,
    
    /// プロフィール画像URL（Googleサインイン時に設定される場合がある）
    String? photoURL,
    
    /// アカウント作成日時
    required DateTime createdAt,
    
    /// 最終アクティビティ日時（セッション管理用）
    required DateTime lastActivityAt,
    
    /// 認証プロバイダー（"email" or "google"）
    required String authProvider,
    
    /// 削除フラグ（論理削除用、Phase 0では未使用）
    @Default(false) bool isDeleted,
  }) = _UserModel;

  /// Firestoreドキュメントから生成
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  /// FirestoreのTimestampをDateTimeに変換するカスタムコンバーター
  static UserModel fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActivityAt: (data['lastActivityAt'] as Timestamp).toDate(),
      authProvider: data['authProvider'] as String,
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  /// FirestoreドキュメントへのMap変換
  static Map<String, dynamic> toFirestore(UserModel user) {
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'createdAt': Timestamp.fromDate(user.createdAt),
      'lastActivityAt': Timestamp.fromDate(user.lastActivityAt),
      'authProvider': user.authProvider,
      'isDeleted': user.isDeleted,
    };
  }
}

# Firebase Scripts

## seed-test-data.js

Firestore Emulatorにテストデータを投入するスクリプトです。無限スクロールなどの機能をテストするために、大量のタスクを持つプロジェクトを作成します。

### 生成されるデータ

- **プロジェクト1**: スタートアッププロジェクト（10タスク、50%完了）
- **プロジェクト2**: 中規模開発プロジェクト（50タスク、30%完了）
- **プロジェクト3**: 大規模エンタープライズプロジェクト（**200タスク**、20%完了）← 無限スクロールテスト用
- **プロジェクト4**: 完了済みプロジェクト（20タスク、100%完了）
- **プロジェクト5**: 期限切れタスク多数（30タスク、10%完了、60%期限切れ）

**総タスク数**: 310個

### 使用方法

#### 1. Firebase Emulatorを起動

```bash
cd firebase
firebase emulators:start
```

#### 2. 別のターミナルでスクリプトを実行

**方法A**: デフォルトのユーザーIDで実行

```bash
cd firebase/functions
node ../scripts/seed-test-data.js
```

デフォルトのユーザーID: `test-user-001`

**方法B**: カスタムユーザーIDを指定

```bash
# 引数で指定
cd firebase/functions
node ../scripts/seed-test-data.js YOUR_USER_ID

# または環境変数で指定
TEST_USER_ID=YOUR_USER_ID node ../scripts/seed-test-data.js
```

#### 3. アプリで確認

Flutterアプリを起動して、認証後に自動的に作成されたプロジェクトとタスクが表示されることを確認します。

```bash
cd ../flutter_app
fvm flutter run
```

### ユーザーIDの取得方法

Flutterアプリで認証後、以下の方法でユーザーIDを取得できます：

1. **Firebase Emulator UIから取得**
   - http://localhost:4000/auth にアクセス
   - 認証済みユーザーのUIDをコピー

2. **Flutterアプリのコードで確認**
   ```dart
   final user = FirebaseAuth.instance.currentUser;
   print('User ID: ${user?.uid}');
   ```

3. **Firestoreのドキュメントから確認**
   - http://localhost:4000/firestore にアクセス
   - `projects`コレクションを開いて既存のドキュメントの`userId`を確認

### トラブルシューティング

**エラー: "FIRESTORE_EMULATOR_HOST is not defined"**

→ Firebase Emulatorが起動していることを確認してください。

**エラー: "Permission denied"**

→ Firestore Emulatorではセキュリティルールが適用されません。このエラーが出る場合は、本番環境に接続している可能性があります。`FIRESTORE_EMULATOR_HOST`の設定を確認してください。

**データが表示されない**

1. ユーザーIDが正しいか確認
2. Firestore Emulator UI (http://localhost:4000/firestore) でデータが作成されているか確認
3. Flutterアプリが正しくEmulatorに接続しているか確認（`main.dart`の設定）

### データのクリア

スクリプトを実行すると、指定したユーザーIDの既存のプロジェクトとタスクが自動的にクリアされます。

手動でクリアする場合は、Firestore Emulator UIから削除できます：
http://localhost:4000/firestore

### 注意事項

⚠️ **このスクリプトはEmulator専用です**

本番環境では絶対に実行しないでください。スクリプト内で`FIRESTORE_EMULATOR_HOST`を設定しているため、通常は本番に影響しませんが、念のため確認してから実行してください。

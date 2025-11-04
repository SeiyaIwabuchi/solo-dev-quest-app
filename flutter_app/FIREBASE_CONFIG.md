# Firebase設定管理

## 概要

このプロジェクトでは、Firebase設定を`--dart-define`でJSON形式で渡すことで、セキュアに管理しています。

## 開発環境 (Emulator使用時)

開発環境では特別な設定は不要です。自動的にEmulator用のダミー設定が使用されます。

```bash
# Emulatorを起動
cd firebase
npm run emulators

# 別ターミナルでアプリを起動
cd flutter_app
fvm flutter run
```

### VS Codeから実行する場合

1. VS Codeのデバッグパネルを開く
2. **「flutter_app (Emulator)」**を選択して実行

## 開発環境で本番に接続する場合

### 1. 設定ファイルの準備

`firebase_config.production.env`を編集して実際のFirebase設定を記述:

```env
# 共通設定
FIREBASE_PROJECT_ID=project_id
FIREBASE_MESSAGING_SENDER_ID=YOUR_ACTUAL_MESSAGING_SENDER_ID
FIREBASE_STORAGE_BUCKET=project_id.appspot.com

# Android設定
FIREBASE_ANDROID_API_KEY=YOUR_ACTUAL_ANDROID_API_KEY
FIREBASE_ANDROID_APP_ID=1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID

# iOS設定
FIREBASE_IOS_API_KEY=YOUR_ACTUAL_IOS_API_KEY
FIREBASE_IOS_APP_ID=1:YOUR_PROJECT_NUMBER:ios:YOUR_APP_ID
FIREBASE_IOS_BUNDLE_ID=com.example.soloDev
```

### 2. VS Codeから実行

1. VS Codeのデバッグパネルを開く
2. **「flutter_app (Production)」**を選択して実行

これで本番のFirebaseに接続されます。

### 3. コマンドラインから実行

```bash
cd flutter_app
fvm flutter run --dart-define-from-file=firebase_config.production.env
```

## 本番環境 (実際のFirebaseプロジェクト使用時)

### 1. Firebase設定JSONの準備

`firebase_config.json` (このファイルは.gitignoreに追加すること):

```json
{
  "android": {
    "apiKey": "YOUR_ANDROID_API_KEY",
    "appId": "YOUR_ANDROID_APP_ID",
    "messagingSenderId": "YOUR_MESSAGING_SENDER_ID",
    "projectId": "YOUR_PROJECT_ID",
    "storageBucket": "YOUR_STORAGE_BUCKET"
  },
  "ios": {
    "apiKey": "YOUR_IOS_API_KEY",
    "appId": "YOUR_IOS_APP_ID",
    "messagingSenderId": "YOUR_MESSAGING_SENDER_ID",
    "projectId": "YOUR_PROJECT_ID",
    "storageBucket": "YOUR_STORAGE_BUCKET",
    "iosBundleId": "YOUR_IOS_BUNDLE_ID"
  }
}
```

### 2. ビルド時に設定を渡す

#### コマンドラインで直接指定

```bash
# Android
fvm flutter run --dart-define=FIREBASE_CONFIG='{"android":{"apiKey":"..."},"ios":{...}}'

# iOS
fvm flutter run --dart-define=FIREBASE_CONFIG='{"android":{...},"ios":{"apiKey":"..."}}'
```

#### ファイルから読み込んで指定

```bash
# macOS/Linux
fvm flutter build apk --dart-define=FIREBASE_CONFIG="$(cat firebase_config.json | tr -d '\n')"

# または、より安全な方法
export FIREBASE_CONFIG=$(cat firebase_config.json | tr -d '\n')
fvm flutter build apk --dart-define=FIREBASE_CONFIG="$FIREBASE_CONFIG"
```

## GitHub Actions での使用

GitHub Secretsに`FIREBASE_CONFIG_JSON`として設定を保存し、ビルド時に使用します。

```yaml
- name: Build Android App
  run: |
    cd flutter_app
    flutter build apk \
      --dart-define=FIREBASE_CONFIG='${{ secrets.FIREBASE_CONFIG_JSON }}'
```

## セキュリティ上の注意

1. **firebase_config.json は .gitignore に追加すること**
2. **GitHub Secrets に FIREBASE_CONFIG_JSON を設定すること**
3. **本番のAPIキーやApp IDをコードにハードコードしないこと**

## トラブルシューティング

### 設定が読み込まれない

開発モードで実行すると、コンソールに以下のようなメッセージが表示されます:

```
⚠️ FIREBASE_CONFIG not found in dart-define. Using default emulator config.
```

これはEmulator用のダミー設定が使用されていることを示します。本番ビルドの場合は、`--dart-define`で設定を渡してください。

### JSONパースエラー

設定のJSON形式が正しいか確認してください:

```bash
# JSON の構文チェック
cat firebase_config.json | jq .
```

## 参考

- [Firebase CLI](https://firebase.google.com/docs/cli)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli)
- [Dart-define in Flutter](https://docs.flutter.dev/deployment/flavors#dart-defines)

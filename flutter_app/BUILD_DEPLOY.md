# Flutter アプリのビルドとデプロイ設定

## GitHub Secretsに追加すべき設定

以下の個別のシークレットを設定します:

### Firebase設定

| Secret名 | 値の例 | 説明 |
|---------|--------|------|
| `FIREBASE_PROJECT_ID` | `project` | Firebase プロジェクトID |
| `FIREBASE_MESSAGING_SENDER_ID` | `123456789012` | メッセージング送信者ID |
| `FIREBASE_STORAGE_BUCKET` | `project_id.appspot.com` | ストレージバケット |
| `FIREBASE_ANDROID_API_KEY` | `AIzaSy...` | Android用APIキー |
| `FIREBASE_ANDROID_APP_ID` | `1:123456789012:android:abc123` | Android用アプリID |
| `FIREBASE_IOS_API_KEY` | `AIzaSy...` | iOS用APIキー |
| `FIREBASE_IOS_APP_ID` | `1:123456789012:ios:def456` | iOS用アプリID |
| `FIREBASE_IOS_BUNDLE_ID` | `com.example.soloDev` | iOSバンドルID |

**設定方法:**
1. GitHub リポジトリ → Settings → Secrets and variables → Actions
2. "New repository secret" をクリック
3. 上記の各Secret名と値を設定
4. "Add secret" をクリック

## GitHub Actions ワークフロー例

```yaml
name: Build and Deploy Flutter App

on:
  push:
    branches:
      - production
  workflow_dispatch:

jobs:
  build-android:
    name: Build Android APK
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.7'
          channel: 'stable'
      
      - name: Get dependencies
        run: |
          cd flutter_app
          flutter pub get
      
      - name: Create Firebase config file
        run: |
          cd flutter_app
          cat > firebase_config.production.env << EOF
          FIREBASE_PROJECT_ID=${{ secrets.FIREBASE_PROJECT_ID }}
          FIREBASE_MESSAGING_SENDER_ID=${{ secrets.FIREBASE_MESSAGING_SENDER_ID }}
          FIREBASE_STORAGE_BUCKET=${{ secrets.FIREBASE_STORAGE_BUCKET }}
          FIREBASE_ANDROID_API_KEY=${{ secrets.FIREBASE_ANDROID_API_KEY }}
          FIREBASE_ANDROID_APP_ID=${{ secrets.FIREBASE_ANDROID_APP_ID }}
          FIREBASE_IOS_API_KEY=${{ secrets.FIREBASE_IOS_API_KEY }}
          FIREBASE_IOS_APP_ID=${{ secrets.FIREBASE_IOS_APP_ID }}
          FIREBASE_IOS_BUNDLE_ID=${{ secrets.FIREBASE_IOS_BUNDLE_ID }}
          EOF
      
      - name: Build APK with Firebase config
        run: |
          cd flutter_app
          flutter build apk --release \
            --dart-define-from-file=firebase_config.production.env
      
      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-release.apk
          path: flutter_app/build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    name: Build iOS IPA
    runs-on: macos-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.7'
          channel: 'stable'
      
      - name: Get dependencies
        run: |
          cd flutter_app
          flutter pub get
      
      - name: Create Firebase config file
        run: |
          cd flutter_app
          cat > firebase_config.production.env << EOF
          FIREBASE_PROJECT_ID=${{ secrets.FIREBASE_PROJECT_ID }}
          FIREBASE_MESSAGING_SENDER_ID=${{ secrets.FIREBASE_MESSAGING_SENDER_ID }}
          FIREBASE_STORAGE_BUCKET=${{ secrets.FIREBASE_STORAGE_BUCKET }}
          FIREBASE_ANDROID_API_KEY=${{ secrets.FIREBASE_ANDROID_API_KEY }}
          FIREBASE_ANDROID_APP_ID=${{ secrets.FIREBASE_ANDROID_APP_ID }}
          FIREBASE_IOS_API_KEY=${{ secrets.FIREBASE_IOS_API_KEY }}
          FIREBASE_IOS_APP_ID=${{ secrets.FIREBASE_IOS_APP_ID }}
          FIREBASE_IOS_BUNDLE_ID=${{ secrets.FIREBASE_IOS_BUNDLE_ID }}
          EOF
      
      - name: Build iOS without codesigning
        run: |
          cd flutter_app
          flutter build ios --release --no-codesign \
            --dart-define-from-file=firebase_config.production.env
      
      - name: Upload IPA artifact
        uses: actions/upload-artifact@v4
        with:
          name: Runner.app
          path: flutter_app/build/ios/iphoneos/Runner.app
```

## ローカルでのビルド方法

### 設定ファイルの準備

`flutter_app/firebase_config.production.env` を編集して実際の値を設定:

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

### ビルドコマンド

```bash
cd flutter_app

# Android
fvm flutter build apk --release \
  --dart-define-from-file=firebase_config.production.env

# iOS
fvm flutter build ios --release \
  --dart-define-from-file=firebase_config.production.env
```

## 注意事項

1. `firebase_config.production.env` は .gitignore に追加されているため、コミットされません
2. 本番環境の設定は GitHub Secrets で管理します
3. 開発環境では Firebase Emulator を使用するため、設定ファイルは不要です
4. VS Codeから実行する場合は、デバッグパネルで「flutter_app (Production)」を選択

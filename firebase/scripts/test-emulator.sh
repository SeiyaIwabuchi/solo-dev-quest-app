#!/bin/bash
# Firebase Emulatorをテスト用ルールで起動するスクリプト

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIREBASE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$FIREBASE_DIR"

echo "📋 本番用ルールをバックアップ中..."
if [ ! -f firestore.rules.production ]; then
  cp firestore.rules firestore.rules.production
  echo "✅ firestore.rules.production を作成しました"
else
  echo "ℹ️  firestore.rules.production は既に存在します"
fi

echo "🔄 テスト用ルールに切り替え中..."
cp firestore.rules.test firestore.rules

echo "🚀 Firebase Emulatorを起動中..."
echo "⚠️  終了時は Ctrl+C を押してください"
echo ""

# トラップを設定して、終了時に本番用ルールを復元
trap 'echo ""; echo "🔄 本番用ルールに復元中..."; cp firestore.rules.production firestore.rules; echo "✅ 復元完了"; exit' INT TERM

firebase emulators:start --only auth,firestore

# 通常終了の場合も復元
echo ""
echo "🔄 本番用ルールに復元中..."
cp firestore.rules.production firestore.rules
echo "✅ 復元完了"

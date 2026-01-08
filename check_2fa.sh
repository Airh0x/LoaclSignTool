#!/bin/bash

# 2FA関連のトラブルシューティングスクリプト

echo "=== 2FA トラブルシューティング ==="
echo ""

# Builderサーバーの確認
echo "1. Builderサーバーの状態確認..."
if lsof -ti:8090 > /dev/null 2>&1; then
    echo "   ✓ Builderサーバーは起動中"
else
    echo "   ✗ Builderサーバーが起動していません"
fi

# SignToolsサービスの確認
echo "2. SignToolsサービスの状態確認..."
if lsof -ti:8080 > /dev/null 2>&1; then
    echo "   ✓ SignToolsサービスは起動中"
    echo "   Webインターフェース: http://localhost:8080"
else
    echo "   ✗ SignToolsサービスが起動していません"
fi

# Builderログの確認
echo ""
echo "3. Builderサーバーのログ確認..."
if [ -f "SignTools-Builder/builder.log" ]; then
    echo "   最近のログ（2FA関連）:"
    tail -30 SignTools-Builder/builder.log | grep -i -E "2fa|auth|login|error|fastlane" || echo "   2FA関連のログが見つかりません"
else
    echo "   ログファイルが見つかりません"
fi

# プロファイルの確認
echo ""
echo "4. 署名プロファイルの確認..."
if [ -f "data/profiles/developer_account/account_name.txt" ]; then
    echo "   アカウント名: $(cat data/profiles/developer_account/account_name.txt)"
    echo "   ✓ 開発者アカウントプロファイルが設定されています"
else
    echo "   ✗ 開発者アカウントプロファイルが見つかりません"
fi

echo ""
echo "=== 確認事項 ==="
echo "1. Appleから2FAコードが届いていますか？"
echo "   - メール（Apple Developer Accountのメールアドレス）"
echo "   - SMS（登録された電話番号）"
echo "   - 信頼できるデバイスへの通知"
echo ""
echo "2. Webインターフェースで「Submit 2FA」ボタンをクリックしましたか？"
echo "   URL: http://localhost:8080"
echo ""
echo "3. 2FAコードは60秒以内に入力する必要があります"
echo ""
echo "4. Apple Developer Accountの設定を確認してください："
echo "   - 2FAが有効になっているか"
echo "   - 信頼できるデバイスが登録されているか"
echo "   - メールアドレスや電話番号が正しいか"

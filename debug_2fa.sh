#!/bin/bash

# 2FAデバッグスクリプト
# Apple Developerアカウントの2FA設定を確認します

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$SCRIPT_DIR/data/profiles/developer_account"

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== 2FAデバッグスクリプト ===${NC}"
echo ""

# 1. プロファイルファイルの確認
echo -e "${YELLOW}1. プロファイルファイルの確認${NC}"
if [ ! -d "$PROFILE_DIR" ]; then
    echo -e "${RED}✗ プロファイルディレクトリが見つかりません: $PROFILE_DIR${NC}"
    exit 1
fi

if [ ! -f "$PROFILE_DIR/account_name.txt" ]; then
    echo -e "${RED}✗ account_name.txtが見つかりません${NC}"
    exit 1
fi

if [ ! -f "$PROFILE_DIR/account_pass.txt" ]; then
    echo -e "${RED}✗ account_pass.txtが見つかりません${NC}"
    exit 1
fi

ACCOUNT_NAME=$(cat "$PROFILE_DIR/account_name.txt" | tr -d '[:space:]')
ACCOUNT_PASS=$(cat "$PROFILE_DIR/account_pass.txt" | tr -d '[:space:]')

echo -e "${GREEN}✓ アカウント名: ${ACCOUNT_NAME}${NC}"
echo -e "${GREEN}✓ パスワード: ${#ACCOUNT_PASS}文字${NC}"
echo ""

# 2. fastlaneの確認
echo -e "${YELLOW}2. fastlaneの確認${NC}"
if ! command -v fastlane &> /dev/null; then
    echo -e "${RED}✗ fastlaneがインストールされていません${NC}"
    exit 1
fi

FASTLANE_VERSION=$(fastlane --version 2>&1 | head -1)
echo -e "${GREEN}✓ fastlane: $FASTLANE_VERSION${NC}"
echo ""

# 3. fastlane spaceauthのテスト
echo -e "${YELLOW}3. fastlane spaceauthのテスト${NC}"
echo "注意: このテストは実際にAppleにログインを試みます"
echo "2FAコードが送信される可能性があります"
echo ""
read -p "続行しますか? (y/n): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "テストをスキップしました"
    exit 0
fi

echo ""
echo "fastlane spaceauthを実行中..."
echo "（60秒以内に2FAコードが届くか確認してください）"
echo ""

export FASTLANE_USER="$ACCOUNT_NAME"
export FASTLANE_PASSWORD="$ACCOUNT_PASS"

# fastlane spaceauthを実行（タイムアウト60秒）
timeout 60 fastlane spaceauth 2>&1 | tee /tmp/fastlane_auth_test.log

AUTH_RESULT=$?

echo ""
if [ $AUTH_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ fastlane認証が成功しました${NC}"
elif [ $AUTH_RESULT -eq 124 ]; then
    echo -e "${YELLOW}⚠ タイムアウト（60秒）${NC}"
    echo "2FAコードが届かなかった可能性があります"
    echo ""
    echo "考えられる原因:"
    echo "1. Apple Developerアカウントの2FAが有効になっていない"
    echo "2. メールアドレスが間違っている"
    echo "3. アカウントがロックされている"
    echo "4. ネットワークの問題"
else
    echo -e "${RED}✗ fastlane認証に失敗しました（終了コード: $AUTH_RESULT）${NC}"
    echo ""
    echo "エラーログ:"
    cat /tmp/fastlane_auth_test.log | tail -20
fi

echo ""
echo -e "${YELLOW}4. ログファイルの確認${NC}"
echo "詳細なログ: /tmp/fastlane_auth_test.log"
echo ""

# 4. 推奨事項
echo -e "${YELLOW}5. 推奨事項${NC}"
echo "1. Apple Developerアカウントにログインして2FAが有効か確認"
echo "2. メールアドレス（$ACCOUNT_NAME）が正しいか確認"
echo "3. Apple Developer Portalでアカウントの状態を確認"
echo "4. 必要に応じて、Appleサポートに連絡"
echo ""

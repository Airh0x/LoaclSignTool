#!/bin/bash

# 2FA debug script
# Checks Apple Developer Account 2FA configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$SCRIPT_DIR/data/profiles/developer_account"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== 2FA Debug Script ===${NC}"
echo ""

# 1. Check profile files
echo -e "${YELLOW}1. Checking profile files${NC}"
if [ ! -d "$PROFILE_DIR" ]; then
    echo -e "${RED}✗ Profile directory not found: $PROFILE_DIR${NC}"
    exit 1
fi

if [ ! -f "$PROFILE_DIR/account_name.txt" ]; then
    echo -e "${RED}✗ account_name.txt not found${NC}"
    exit 1
fi

if [ ! -f "$PROFILE_DIR/account_pass.txt" ]; then
    echo -e "${RED}✗ account_pass.txt not found${NC}"
    exit 1
fi

ACCOUNT_NAME=$(cat "$PROFILE_DIR/account_name.txt" | tr -d '[:space:]')
ACCOUNT_PASS=$(cat "$PROFILE_DIR/account_pass.txt" | tr -d '[:space:]')

echo -e "${GREEN}✓ Account name: ${ACCOUNT_NAME}${NC}"
echo -e "${GREEN}✓ Password: ${#ACCOUNT_PASS} characters${NC}"
echo ""

# 2. Check fastlane
echo -e "${YELLOW}2. Checking fastlane${NC}"
if ! command -v fastlane &> /dev/null; then
    echo -e "${RED}✗ fastlane is not installed${NC}"
    exit 1
fi

FASTLANE_VERSION=$(fastlane --version 2>&1 | head -1)
echo -e "${GREEN}✓ fastlane: $FASTLANE_VERSION${NC}"
echo ""

# 3. Test fastlane spaceauth
echo -e "${YELLOW}3. Testing fastlane spaceauth${NC}"
echo "Note: This test will attempt to log in to Apple"
echo "A 2FA code may be sent"
echo ""
read -p "Continue? (y/n): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Test skipped"
    exit 0
fi

echo ""
echo "Running fastlane spaceauth..."
echo "(Check if 2FA code arrives within 60 seconds)"
echo ""

export FASTLANE_USER="$ACCOUNT_NAME"
export FASTLANE_PASSWORD="$ACCOUNT_PASS"

# Run fastlane spaceauth (60 second timeout)
timeout 60 fastlane spaceauth 2>&1 | tee /tmp/fastlane_auth_test.log

AUTH_RESULT=$?

echo ""
if [ $AUTH_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ fastlane authentication succeeded${NC}"
elif [ $AUTH_RESULT -eq 124 ]; then
    echo -e "${YELLOW}⚠ Timeout (60 seconds)${NC}"
    echo "2FA code may not have arrived"
    echo ""
    echo "Possible causes:"
    echo "1. 2FA is not enabled on Apple Developer Account"
    echo "2. Email address is incorrect"
    echo "3. Account is locked"
    echo "4. Network issue"
else
    echo -e "${RED}✗ fastlane authentication failed (exit code: $AUTH_RESULT)${NC}"
    echo ""
    echo "Error log:"
    cat /tmp/fastlane_auth_test.log | tail -20
fi

echo ""
echo -e "${YELLOW}4. Check log file${NC}"
echo "Detailed log: /tmp/fastlane_auth_test.log"
echo ""

# 4. Recommendations
echo -e "${YELLOW}5. Recommendations${NC}"
echo "1. Log in to Apple Developer Account and verify 2FA is enabled"
echo "2. Verify email address ($ACCOUNT_NAME) is correct"
echo "3. Check account status in Apple Developer Portal"
echo "4. Contact Apple Support if necessary"
echo ""

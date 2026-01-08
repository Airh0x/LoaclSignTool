#!/bin/bash

# 2FA troubleshooting script

echo "=== 2FA Troubleshooting ==="
echo ""

# Check Builder server status
echo "1. Checking Builder server status..."
if lsof -ti:8090 > /dev/null 2>&1; then
    echo "   ✓ Builder server is running"
else
    echo "   ✗ Builder server is not running"
fi

# Check SignTools service status
echo "2. Checking SignTools service status..."
if lsof -ti:8080 > /dev/null 2>&1; then
    echo "   ✓ SignTools service is running"
    echo "   Web interface: http://localhost:8080"
else
    echo "   ✗ SignTools service is not running"
fi

# Check Builder logs
echo ""
echo "3. Checking Builder server logs..."
if [ -f "SignTools-Builder/builder.log" ]; then
    echo "   Recent logs (2FA related):"
    tail -30 SignTools-Builder/builder.log | grep -i -E "2fa|auth|login|error|fastlane" || echo "   No 2FA-related logs found"
else
    echo "   Log file not found"
fi

# Check profile
echo ""
echo "4. Checking signing profile..."
if [ -f "data/profiles/developer_account/account_name.txt" ]; then
    echo "   Account name: $(cat data/profiles/developer_account/account_name.txt)"
    echo "   ✓ Developer account profile is configured"
else
    echo "   ✗ Developer account profile not found"
fi

echo ""
echo "=== Things to Check ==="
echo "1. Are you receiving 2FA codes from Apple?"
echo "   - Email (Apple Developer Account email address)"
echo "   - SMS (registered phone number)"
echo "   - Notification to trusted device"
echo ""
echo "2. Did you click the 'Submit 2FA' button in the web interface?"
echo "   URL: http://localhost:8080"
echo ""
echo "3. 2FA codes must be entered within 60 seconds"
echo ""
echo "4. Check your Apple Developer Account settings:"
echo "   - Is 2FA enabled?"
echo "   - Are trusted devices registered?"
echo "   - Are email address and phone number correct?"

#!/bin/bash

# Test Notarization Credentials Script
# This script helps verify your Apple ID credentials for notarization

set -e

echo "🔍 Testing Apple ID credentials for notarization..."
echo ""

# Check if we have the required environment variables
if [ -z "$APPLE_ID" ]; then
    echo "❌ APPLE_ID environment variable is not set"
    echo "Please run: export APPLE_ID='your-apple-id@example.com'"
    exit 1
fi

if [ -z "$APPLE_ID_PASSWORD" ]; then
    echo "❌ APPLE_ID_PASSWORD environment variable is not set"
    echo "Please run: export APPLE_ID_PASSWORD='your-app-specific-password'"
    exit 1
fi

if [ -z "$TEAM_ID" ]; then
    echo "❌ TEAM_ID environment variable is not set"
    echo "Please run: export TEAM_ID='your-team-id'"
    exit 1
fi

echo "📋 Using credentials:"
echo "   Apple ID: $APPLE_ID"
echo "   Team ID: $TEAM_ID"
echo "   Password: ${APPLE_ID_PASSWORD:0:4}****"
echo ""

# Try to store credentials
echo "🔑 Testing credential storage..."
xcrun notarytool store-credentials "test-profile" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_ID_PASSWORD" \
  --team-id "$TEAM_ID"

if [ $? -eq 0 ]; then
    echo "✅ Credentials stored successfully!"
    
    # List available profiles
    echo ""
    echo "📝 Available notarization profiles:"
    xcrun notarytool history --keychain-profile "test-profile" --format json | head -5 || echo "No history available (this is normal for new accounts)"
    
    # Clean up test profile
    echo ""
    echo "🧹 Cleaning up test profile..."
    security delete-generic-password -s "AC_PASSWORD" -a "$APPLE_ID" -l "test-profile" 2>/dev/null || echo "Profile cleanup completed"
    
else
    echo "❌ Failed to store credentials"
    echo ""
    echo "Common issues:"
    echo "1. Apple ID must be a full email address"
    echo "2. Password must be an app-specific password from https://appleid.apple.com/account/manage"
    echo "3. Team ID must match your Apple Developer account"
    echo "4. Account must have active Apple Developer membership"
    exit 1
fi

echo ""
echo "🎉 Credentials test completed successfully!"

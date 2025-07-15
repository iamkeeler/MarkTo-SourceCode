#!/bin/bash

# Script to regenerate and update GitHub secrets for CI/CD
# This script exports certificates and updates GitHub secrets

set -e

echo "🔐 Certificate Export and GitHub Secrets Update Script"
echo "======================================================"

# Configuration
CERT_PASSWORD="MarkTo-CI-2025"  # Using a consistent password
APP_CERT_NAME="Developer ID Application: Gary Keeler (XZC4QKL34R)"
INSTALLER_CERT_NAME="Developer ID Installer: Gary Keeler (XZC4QKL34R)"

# Temporary file names
APP_CERT_P12="app_cert_temp.p12"
INSTALLER_CERT_P12="installer_cert_temp.p12"

# Function to cleanup temporary files
cleanup() {
    echo "🧹 Cleaning up temporary files..."
    rm -f "$APP_CERT_P12" "$INSTALLER_CERT_P12"
}

# Set cleanup trap
trap cleanup EXIT

echo "📦 Exporting Developer ID Application certificate..."
security export -f pkcs12 -k login.keychain -P "$CERT_PASSWORD" -t identities -o "$APP_CERT_P12" "$APP_CERT_NAME"

echo "📦 Exporting Developer ID Installer certificate..."
security export -f pkcs12 -k login.keychain -P "$CERT_PASSWORD" -t identities -o "$INSTALLER_CERT_P12" "$INSTALLER_CERT_NAME"

echo "✅ Certificates exported successfully"

# Verify the exported certificates can be read with the password using security command
echo "🔍 Verifying exported certificates..."
TEST_KEYCHAIN="verify-test.keychain"
security create-keychain -p "testpass" "$TEST_KEYCHAIN" || true

if ! security import "$APP_CERT_P12" -P "$CERT_PASSWORD" -k "$TEST_KEYCHAIN" -T /usr/bin/codesign >/dev/null 2>&1; then
    echo "❌ Error: Application certificate verification failed"
    security delete-keychain "$TEST_KEYCHAIN" 2>/dev/null || true
    exit 1
fi

if ! security import "$INSTALLER_CERT_P12" -P "$CERT_PASSWORD" -k "$TEST_KEYCHAIN" -T /usr/bin/productbuild >/dev/null 2>&1; then
    echo "❌ Error: Installer certificate verification failed"
    security delete-keychain "$TEST_KEYCHAIN" 2>/dev/null || true
    exit 1
fi

security delete-keychain "$TEST_KEYCHAIN" 2>/dev/null || true
echo "✅ Certificate verification passed"

# Convert to base64
echo "📝 Converting certificates to base64..."
APP_CERT_B64=$(base64 -i "$APP_CERT_P12")
INSTALLER_CERT_B64=$(base64 -i "$INSTALLER_CERT_P12")

echo "🚀 Updating GitHub secrets..."

# Update GitHub secrets
gh secret set DEVELOPER_ID_APPLICATION_P12 --body "$APP_CERT_B64"
gh secret set DEVELOPER_ID_INSTALLER_P12 --body "$INSTALLER_CERT_B64"
gh secret set CERT_PASSWORD --body "$CERT_PASSWORD"

# Update keychain password (using same password for consistency)
gh secret set KEYCHAIN_PASSWORD --body "$CERT_PASSWORD"

echo "✅ GitHub secrets updated successfully!"
echo ""
echo "📋 Summary:"
echo "   - DEVELOPER_ID_APPLICATION_P12: Updated"
echo "   - DEVELOPER_ID_INSTALLER_P12: Updated"
echo "   - CERT_PASSWORD: Updated"
echo "   - KEYCHAIN_PASSWORD: Updated"
echo ""
echo "🎯 You can now re-run the GitHub Actions workflow!"
echo ""
echo "💡 To test the workflow:"
echo "   gh workflow run \"Build and Release MarkTo\""

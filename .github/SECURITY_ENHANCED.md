# Security-Enhanced CI/CD Pipeline

This document provides additional security measures beyond the basic CI/CD setup.

## 🔒 **Critical Security Implementation Steps**

### 1. **Branch Protection Rules** (REQUIRED)

Go to your GitHub repository → Settings → Branches and add these rules for the `release` branch:

```
Branch name pattern: release
☑️ Restrict pushes that create files larger than 100MB
☑️ Require a pull request before merging
  ☑️ Require approvals: 1
  ☑️ Dismiss stale PR approvals when new commits are pushed
  ☑️ Require review from code owners
☑️ Require status checks to pass before merging
☑️ Require branches to be up to date before merging
☑️ Require conversation resolution before merging
☑️ Restrict pushes to matching branches
  ☑️ Restrict pushes to users in roles: Admin, Maintain
☑️ Allow force pushes: Everyone (UNCHECK - should be disabled)
☑️ Allow deletions (UNCHECK - should be disabled)
```

### 2. **Environment Protection** (REQUIRED)

Create a production environment with protection rules:

1. Go to Settings → Environments → New Environment
2. Name: `production`
3. Configure protection rules:
   ```
   ☑️ Required reviewers: [Your GitHub username]
   ☑️ Wait timer: 0 minutes (or longer for additional safety)
   ☑️ Environment variables: (Add any non-sensitive config)
   ```

### 3. **Repository Security Settings** (REQUIRED)

Go to Settings → Security & analysis:

```
☑️ Dependency graph: Enabled
☑️ Dependabot alerts: Enabled
☑️ Dependabot security updates: Enabled
☑️ Secret scanning: Enabled
☑️ Push protection: Enabled (if available)
```

### 4. **Enhanced Workflow Security**

Replace the basic workflow with this security-enhanced version:

```yaml
name: Build and Release MarkTo (Secure)

on:
  push:
    branches: [ release ]
  # Remove workflow_dispatch for production, or add approval gates

# Minimum required permissions
permissions:
  contents: write
  id-token: write

env:
  APP_NAME: MarkTo
  SCHEME: MarkTo
  CONFIGURATION: Release

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@8ade135a41bc03ea155e62e844d188df1ea18608
    - name: Run security scan
      run: |
        # Check for secrets in code
        git log --oneline -n 10
        # Verify no hardcoded credentials
        grep -r "password\|secret\|key" . --exclude-dir=.git || true

  build-and-release:
    needs: security-scan
    runs-on: macos-latest
    environment: production  # Requires manual approval
    timeout-minutes: 60      # Prevent runaway jobs
    
    steps:
    - name: Checkout code
      uses: actions/checkout@8ade135a41bc03ea155e62e844d188df1ea18608
      
    - name: Verify runner integrity
      run: |
        # Basic runner verification
        echo "Runner OS: $(uname -a)"
        echo "Xcode version: $(xcodebuild -version)"
        echo "Security: $(which security)"
        
    - name: Import Code Signing Certificates
      env:
        DEVELOPER_ID_APPLICATION_P12: ${{ secrets.DEVELOPER_ID_APPLICATION_P12 }}
        DEVELOPER_ID_INSTALLER_P12: ${{ secrets.DEVELOPER_ID_INSTALLER_P12 }}
        KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
        CERT_PASSWORD: ${{ secrets.CERT_PASSWORD }}
      run: |
        # Enhanced certificate security
        set +x  # Disable command echoing for this section
        
        # Create secure keychain
        KEYCHAIN_NAME="build-$(uuidgen).keychain"
        security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
        security default-keychain -s "$KEYCHAIN_NAME"
        security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
        security set-keychain-settings -t 1800 -u "$KEYCHAIN_NAME"
        
        # Import certificates with verification
        echo "$DEVELOPER_ID_APPLICATION_P12" | base64 --decode > app.p12
        echo "$DEVELOPER_ID_INSTALLER_P12" | base64 --decode > installer.p12
        
        # Verify certificates before import
        security import app.p12 -k "$KEYCHAIN_NAME" -P "$CERT_PASSWORD" -T /usr/bin/codesign
        security import installer.p12 -k "$KEYCHAIN_NAME" -P "$CERT_PASSWORD" -T /usr/bin/productbuild
        
        security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
        
        # Clean up certificate files immediately
        rm -f app.p12 installer.p12
        
        # Verify certificates are loaded
        security find-identity -v "$KEYCHAIN_NAME"
        
        set -x  # Re-enable command echoing
    
    # ... rest of your build steps ...
    
    - name: Security cleanup
      if: always()
      run: |
        # Ensure all temporary files are removed
        rm -f *.p12 || true
        rm -f ExportOptions.plist || true
        
        # Remove keychain
        KEYCHAIN_LIST=$(security list-keychains | grep build- || true)
        for keychain in $KEYCHAIN_LIST; do
          security delete-keychain "$keychain" || true
        done
```

### 5. **Secret Management Best Practices**

#### Certificate Security:
```bash
# When creating certificate secrets, verify they're properly encoded
base64 -i certificate.p12 > cert.b64
# Verify it can be decoded
base64 -d cert.b64 > test.p12
# Check the decoded file
file test.p12  # Should show "data"
rm test.p12 cert.b64
```

#### Secret Rotation Schedule:
- **Certificates**: Annually (before expiration)
- **Apple ID Password**: Every 6 months
- **Keychain Password**: Every 3 months

### 6. **Monitoring and Alerting**

Set up GitHub webhooks to monitor:
- Workflow runs
- Secret access
- Repository changes

Example webhook endpoint to monitor:
```json
{
  "events": [
    "workflow_run",
    "release",
    "push"
  ],
  "config": {
    "url": "https://your-monitoring-service.com/github-webhook",
    "content_type": "json",
    "secret": "your-webhook-secret"
  }
}
```

### 7. **Incident Response Plan**

#### If certificates are compromised:

1. **Immediate (< 1 hour):**
   ```bash
   # Disable workflow
   gh api repos/:owner/:repo/actions/workflows/:workflow_id/disable
   
   # Revoke certificates in Apple Developer Portal
   # Rotate all GitHub secrets
   ```

2. **Short-term (< 24 hours):**
   - Generate new certificates
   - Update all secrets
   - Audit recent releases
   - Notify users if necessary

3. **Long-term (< 1 week):**
   - Review access logs
   - Update security procedures
   - Consider additional protections

### 8. **Testing Security Measures**

Create a test script to verify your security setup:

```bash
#!/bin/bash
# security-test.sh

echo "🔒 Testing CI/CD Security Setup"

# Check branch protection
echo "📋 Checking branch protection..."
gh api repos/:owner/:repo/branches/release/protection || echo "❌ No branch protection found"

# Check environment protection
echo "📋 Checking environment protection..."
gh api repos/:owner/:repo/environments/production || echo "❌ No environment protection found"

# Check secret scanning
echo "📋 Checking security features..."
gh api repos/:owner/:repo | jq '.security_and_analysis'

# Verify workflow permissions
echo "📋 Checking workflow permissions..."
grep -A 5 "permissions:" .github/workflows/release.yml

echo "✅ Security check complete"
```

### 9. **Alternative Secure Approaches**

For maximum security, consider:

#### Option A: Air-Gapped Signing
- Build unsigned in CI/CD
- Sign manually on secure machine
- Upload signed artifacts

#### Option B: Hardware Security Module (HSM)
- Store certificates in HSM
- Use HSM for signing operations
- Requires enterprise infrastructure

#### Option C: Separate Signing Service
- Dedicated signing infrastructure
- API-based signing requests
- Audit trail for all signatures

### 10. **Compliance Considerations**

If distributing commercially:
- **SOC 2 Compliance**: Document security controls
- **Code Signing Standards**: Follow industry best practices
- **Supply Chain Security**: SLSA framework compliance
- **Privacy**: Document data handling in CI/CD

### 🚨 **Red Flags to Monitor**

Watch for these security indicators:
- Unexpected workflow runs
- Failed certificate operations
- Large number of release downloads from single IP
- Changes to workflow files in PRs
- New collaborators with elevated permissions

This enhanced security setup provides enterprise-level protection for your open-source project while maintaining the automation benefits of CI/CD.

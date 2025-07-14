# GitHub Actions CI/CD Setup for MarkTo

This document explains how to configure the automated CI/CD pipeline for building and distributing MarkTo as signed PKG and DMG files.

## Overview

The CI/CD pipeline automatically triggers when commits are pushed to the `release` branch and creates:
- Notarized and signed MarkTo.app
- PKG installer with custom welcome/readme screens
- DMG disk image for drag-and-drop installation
- GitHub release with checksums and release notes

## Required Secrets

You need to configure the following secrets in your GitHub repository settings (Settings → Secrets and variables → Actions):

### Apple Developer Certificates

1. **DEVELOPER_ID_APPLICATION_P12**
   - Export your "Developer ID Application" certificate from Keychain Access as a .p12 file
   - Convert to base64: `base64 -i certificate.p12 | pbcopy`
   - Paste the base64 string as the secret value

2. **DEVELOPER_ID_INSTALLER_P12**
   - Export your "Developer ID Installer" certificate from Keychain Access as a .p12 file
   - Convert to base64: `base64 -i installer.p12 | pbcopy`
   - Paste the base64 string as the secret value

3. **CERT_PASSWORD**
   - The password you used when exporting the .p12 certificates

4. **KEYCHAIN_PASSWORD**
   - A secure password for the temporary build keychain (can be any strong password)

### Apple Developer Account

5. **APPLE_ID**
   - Your Apple Developer account email address

6. **APPLE_ID_PASSWORD**
   - An app-specific password for your Apple ID
   - Generate at: https://appleid.apple.com/account/manage → App-Specific Passwords

7. **TEAM_ID**
   - Your Apple Developer Team ID (found in Apple Developer Portal)

### GitHub Token

8. **GITHUB_TOKEN**
   - This is automatically provided by GitHub Actions (no setup required)

## Setting Up Certificates

### Step 1: Download Certificates from Apple Developer Portal

1. Go to https://developer.apple.com/account/resources/certificates/list
2. Download your "Developer ID Application" certificate
3. Download your "Developer ID Installer" certificate
4. Double-click each to install in Keychain Access

### Step 2: Export Certificates

1. Open Keychain Access
2. Find your "Developer ID Application" certificate
3. Right-click → Export → Choose .p12 format → Set a password
4. Repeat for "Developer ID Installer" certificate

### Step 3: Convert to Base64

```bash
# For Application certificate
base64 -i developer_id_application.p12 | pbcopy

# For Installer certificate  
base64 -i developer_id_installer.p12 | pbcopy
```

## Workflow Trigger

The workflow triggers on:
- Push to `release` branch
- Manual dispatch from GitHub Actions tab

## Build Process

1. **Code Checkout**: Gets latest code from release branch
2. **Certificate Import**: Imports signing certificates into temporary keychain
3. **Build**: Compiles the app with Release configuration
4. **Export**: Exports signed .app bundle
5. **Notarization**: Submits app to Apple for notarization
6. **PKG Creation**: Creates installer package with custom screens
7. **DMG Creation**: Creates disk image for distribution
8. **Release**: Creates GitHub release with all artifacts

## Outputs

Each successful build creates:

- `MarkTo-X.X.X.dmg` - Disk image for drag-and-drop installation
- `MarkTo-X.X.X.pkg` - PKG installer with welcome screens
- `*.sha256` files - Checksums for verification
- GitHub release with automated release notes

## Customization

### Installer Screens

The PKG installer includes custom HTML screens in the workflow:
- **Welcome**: Introduction and what's new
- **ReadMe**: System requirements and usage
- **License**: CC BY-NC 4.0 license information

Edit the HTML content in the workflow file to customize these screens.

### Release Notes

The workflow auto-generates release notes. Customize the template in the "Create release notes" step.

### Version Detection

Version numbers are automatically extracted from `Info.plist`:
- `CFBundleShortVersionString` → Release version (e.g., "1.0.1")
- `CFBundleVersion` → Build number (e.g., "2")

## Testing

### Local Testing

Before pushing to `release` branch, test locally:

```bash
# Build locally to verify
xcodebuild -project MarkTo.xcodeproj -scheme MarkTo -configuration Release build

# Check version extraction
plutil -p MarkTo/Info.plist | grep CFBundleShortVersionString
```

### Workflow Testing

1. Create a test branch from `release`
2. Modify the workflow to trigger on your test branch
3. Push and verify the workflow runs correctly
4. Remove test modifications before merging

## Troubleshooting

### Certificate Issues

**Error**: "No signing certificate found"
- Verify certificates are properly exported as .p12
- Check base64 encoding is correct (no extra characters)
- Ensure TEAM_ID matches your Apple Developer account

### Notarization Issues

**Error**: "Notarization failed"
- Verify APPLE_ID and APPLE_ID_PASSWORD are correct
- Ensure app-specific password is generated for Apple ID
- Check TEAM_ID is valid

### Build Issues

**Error**: "Build failed"
- Verify Xcode project builds locally
- Check scheme name matches in workflow (currently "MarkTo")
- Ensure all dependencies are properly configured

## Security Notes

- Certificates are temporarily imported and immediately deleted
- Keychain is created with unique password and destroyed after build
- All secrets are encrypted and only accessible during workflow execution
- Notarization ensures Apple security compliance

## 🔒 **Security Considerations for Public Repositories**

### ✅ **Current Security Strengths**

The pipeline is designed with several security best practices:

1. **Secret Protection**: All sensitive data uses GitHub Secrets (encrypted at rest)
2. **Ephemeral Certificates**: Certificates are only temporarily imported and immediately deleted
3. **Keychain Isolation**: Temporary keychain is created and destroyed per build
4. **Branch Protection**: Only triggers on `release` branch (controlled access)
5. **No Credential Exposure**: Secrets never appear in logs or outputs

### ⚠️ **Potential Security Risks**

#### **High Priority Risks:**

1. **Pull Request Attacks**
   - **Risk**: Malicious PRs could modify workflow to exfiltrate secrets
   - **Current Status**: ❌ Not protected
   - **Impact**: Certificate theft, Apple ID compromise

2. **Fork Workflows**
   - **Risk**: Forks can access secrets if workflows run on PRs
   - **Current Status**: ❌ Not protected
   - **Impact**: Unauthorized signed binaries

3. **Branch Protection**
   - **Risk**: Anyone with write access can push to `release` branch
   - **Current Status**: ⚠️ Depends on repo settings
   - **Impact**: Unauthorized releases

#### **Medium Priority Risks:**

4. **Dependency Confusion**
   - **Risk**: Malicious packages could be installed during build
   - **Current Status**: ⚠️ Uses external actions
   - **Impact**: Supply chain compromise

5. **Runner Compromise**
   - **Risk**: GitHub-hosted runners could be compromised
   - **Current Status**: ⚠️ Using shared runners
   - **Impact**: Certificate exposure during build

### 🛡️ **Enhanced Security Recommendations**

#### **Immediate Actions (High Priority):**

1. **Restrict Workflow Execution**
   ```yaml
   # Add to workflow file
   on:
     push:
       branches: [ release ]
     # Remove workflow_dispatch for production or add approval gates
   ```

2. **Enable Branch Protection**
   - Go to Settings → Branches
   - Add rule for `release` branch
   - Require PR reviews
   - Require status checks
   - Restrict pushes to specific users

3. **Environment Protection**
   ```yaml
   jobs:
     build-and-release:
       runs-on: macos-latest
       environment: production  # Add environment protection
   ```

4. **Add Secret Scanning**
   - Enable GitHub Advanced Security
   - Monitor for accidental secret exposure

#### **Enhanced Workflow Security:**

Add these improvements to the workflow:

```yaml
# Add at top of workflow
permissions:
  contents: write
  id-token: write  # For OIDC
  packages: read

# Add environment protection
environment: 
  name: production
  url: ${{ steps.release.outputs.html_url }}

# Pin action versions with SHA
- uses: actions/checkout@8ade135a41bc03ea155e62e844d188df1ea18608  # v4.1.0
- uses: softprops/action-gh-release@de2c0eb89ae2a093876385947365aca7b0e5f844  # v1
```

#### **Additional Security Measures:**

5. **Certificate Rotation Schedule**
   - Rotate certificates annually
   - Update secrets immediately after rotation
   - Monitor certificate expiration

6. **Audit Logging**
   - Enable GitHub audit logs
   - Monitor workflow executions
   - Set up alerts for unusual activity

7. **Supply Chain Security**
   ```yaml
   # Add dependency verification
   - name: Verify dependencies
     run: |
       # Verify action checksums
       # Scan for vulnerabilities
   ```

8. **Self-Hosted Runners** (Optional but more secure)
   - Use dedicated macOS runners
   - Better control over build environment
   - Reduced risk of runner compromise

### 🚨 **Emergency Procedures**

If certificates are compromised:

1. **Immediate Actions:**
   - Revoke certificates in Apple Developer Portal
   - Rotate all GitHub secrets
   - Disable workflow runs
   - Audit recent releases

2. **Recovery Steps:**
   - Generate new certificates
   - Update secrets
   - Re-enable workflows
   - Notify users of security incident

### 📋 **Security Checklist**

Before going live:

- [ ] Enable branch protection on `release` branch
- [ ] Set up environment protection with approvals
- [ ] Pin all action versions to specific SHAs
- [ ] Enable secret scanning
- [ ] Configure audit logging
- [ ] Document incident response procedures
- [ ] Test security measures with non-production certificates

### 🔍 **Monitoring & Alerts**

Set up monitoring for:
- Unexpected workflow runs
- Failed certificate operations
- Unusual download patterns of releases
- Security alerts from GitHub

### 💡 **Alternative Approaches**

For maximum security, consider:

1. **Manual Release Process**: Keep CI/CD for testing, manual releases for production
2. **Separate Signing Infrastructure**: Use dedicated signing servers
3. **Hardware Security Modules (HSM)**: For enterprise-level certificate protection

## Release Process

To create a new release:

1. Update version in `Info.plist`
2. Commit changes to `main` branch
3. Create and push `release` branch:
   ```bash
   git checkout main
   git checkout -b release
   git push origin release
   ```
4. Workflow automatically builds and creates GitHub release
5. Delete `release` branch after successful build if desired

## Manual Trigger

You can also trigger builds manually:
1. Go to GitHub Actions tab
2. Select "Build and Release MarkTo" workflow
3. Click "Run workflow"
4. Choose the `release` branch
5. Click "Run workflow"

This gives you full control over when releases are created while maintaining the automated build process.

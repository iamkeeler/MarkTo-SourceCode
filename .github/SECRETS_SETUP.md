# 🔐 GitHub Secrets Configuration Guide

## Step 1: Create Developer ID Certificates (REQUIRED)

You need to create Developer ID certificates in Apple Developer Portal before configuring GitHub secrets.

### 1.1 Create Developer ID Application Certificate

1. **Go to Apple Developer Portal:**
   - Visit: https://developer.apple.com/account/resources/certificates/list
   - Sign in with your Apple Developer account

2. **Create Certificate:**
   - Click the **"+"** button to add a new certificate
   - Select **"Developer ID Application"**
   - Click **"Continue"**

3. **Generate Certificate Signing Request (CSR):**
   ```bash
   # Run this command in Terminal to create a CSR:
   openssl req -new -newkey rsa:2048 -nodes -keyout developer_id_application.key -out developer_id_application.csr -subj "/CN=Developer ID Application/O=Your Name/C=US"
   ```
   
4. **Upload CSR:**
   - Upload the `developer_id_application.csr` file
   - Download the generated certificate (`developer_id_application.cer`)

5. **Install Certificate:**
   ```bash
   # Install the certificate and key
   security import developer_id_application.cer -k ~/Library/Keychains/login.keychain
   security import developer_id_application.key -k ~/Library/Keychains/login.keychain
   ```

### 1.2 Create Developer ID Installer Certificate

1. **Repeat the same process:**
   - In Apple Developer Portal, click **"+"** again
   - Select **"Developer ID Installer"**
   - Click **"Continue"**

2. **Generate CSR for installer:**
   ```bash
   openssl req -new -newkey rsa:2048 -nodes -keyout developer_id_installer.key -out developer_id_installer.csr -subj "/CN=Developer ID Installer/O=Your Name/C=US"
   ```

3. **Upload CSR and download certificate**
4. **Install Certificate:**
   ```bash
   security import developer_id_installer.cer -k ~/Library/Keychains/login.keychain
   security import developer_id_installer.key -k ~/Library/Keychains/login.keychain
   ```

---

## Step 2: Export Certificates for GitHub Secrets

### 2.1 Verify Certificates Are Installed

```bash
# Check for Developer ID certificates
security find-identity -v | grep "Developer ID"
```

You should see something like:
```
1) ABC123... "Developer ID Application: Your Name (TEAMID)"
2) DEF456... "Developer ID Installer: Your Name (TEAMID)"
```

### 2.2 Export Certificates as P12 Files

**Export Developer ID Application:**
1. Open **Keychain Access** application
2. Find **"Developer ID Application: Your Name (TEAMID)"**
3. Right-click → **"Export"**
4. Choose format: **"Personal Information Exchange (.p12)"**
5. Save as: `developer_id_application.p12`
6. Set a strong password (remember it for GitHub secrets)

**Export Developer ID Installer:**
1. Find **"Developer ID Installer: Your Name (TEAMID)"**
2. Right-click → **"Export"**
3. Choose format: **"Personal Information Exchange (.p12)"**
4. Save as: `developer_id_installer.p12`
5. Use the same password as above

### 2.3 Convert to Base64 for GitHub Secrets

```bash
# Convert Application certificate
base64 -i developer_id_application.p12 | pbcopy
# Paste this as DEVELOPER_ID_APPLICATION_P12 secret

# Convert Installer certificate  
base64 -i developer_id_installer.p12 | pbcopy
# Paste this as DEVELOPER_ID_INSTALLER_P12 secret
```

---

## Step 3: Get Apple Developer Information

### 3.1 Find Your Team ID
1. Go to https://developer.apple.com/account
2. Look for **"Team ID"** in the membership details
3. It's a 10-character string like **"ABC1234567"**

### 3.2 Create App-Specific Password
1. Go to https://appleid.apple.com/account/manage
2. Sign in with your Apple ID
3. Go to **"Security"** → **"App-Specific Passwords"**
4. Click **"Generate Password"**
5. Label: **"MarkTo CI/CD"**
6. Copy the generated password (format: xxxx-xxxx-xxxx-xxxx)

---

## Step 4: Configure GitHub Repository Secrets

### 4.1 Access Repository Secrets
Go to: https://github.com/iamkeeler/MarkTo-SourceCode/settings/secrets/actions

### 4.2 Add Each Secret

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `DEVELOPER_ID_APPLICATION_P12` | Base64 encoded .p12 file | Your Developer ID Application certificate |
| `DEVELOPER_ID_INSTALLER_P12` | Base64 encoded .p12 file | Your Developer ID Installer certificate |
| `CERT_PASSWORD` | Your .p12 password | Password you set when exporting certificates |
| `KEYCHAIN_PASSWORD` | Strong random password | Used for temporary build keychain |
| `APPLE_ID` | your@apple.id | Your Apple Developer account email |
| `APPLE_ID_PASSWORD` | xxxx-xxxx-xxxx-xxxx | App-specific password from Apple ID |
| `TEAM_ID` | ABC1234567 | Your Apple Developer Team ID |

### 4.3 Click "New repository secret" for each one

1. Enter the **Name** exactly as shown above
2. Paste the **Value** 
3. Click **"Add secret"**

---

## Step 5: Verify Setup

### 5.1 Test Certificates Locally
```bash
# Verify you can sign with the certificates
codesign --verify --verbose /Applications/Calculator.app || echo "Certificates not ready"

# Check certificate validity
security find-identity -v | grep "Developer ID"
```

### 5.2 Check GitHub Secrets
```bash
# List configured secrets (won't show values)
gh secret list --repo iamkeeler/MarkTo-SourceCode
```

You should see all 7 secrets listed.

---

## Step 6: Test the CI/CD Pipeline

### 6.1 Create a Test Release
```bash
# Create a test branch
git checkout -b test-cicd-setup

# Make a small change
echo "# CI/CD Test" >> TEST_RELEASE.md
git add TEST_RELEASE.md
git commit -m "Test CI/CD pipeline setup"

# Push to create PR
git push origin test-cicd-setup

# Create PR to release branch
gh pr create --base release --title "Test CI/CD Setup" --body "Testing the secure CI/CD pipeline"
```

### 6.2 Monitor the Process
1. **Review and Merge PR** to release branch
2. **Watch GitHub Actions** tab for workflow run
3. **Approve Deployment** when prompted (production environment)
4. **Check Release** is created with signed PKG and DMG

---

## Troubleshooting

### Certificate Issues
```bash
# If certificates aren't working:
security delete-certificate -c "Developer ID Application" || true
security delete-certificate -c "Developer ID Installer" || true
# Then re-import following Step 1
```

### Secret Issues
- Ensure base64 encoding has no extra spaces or newlines
- Verify certificate passwords are correct
- Check Apple ID credentials are valid

### Workflow Issues
- Check GitHub Actions logs for specific errors
- Verify all 7 secrets are configured
- Ensure production environment approval is given

---

## Security Notes

- **Never commit .p12 files or private keys to git**
- **Use strong, unique passwords for certificates**
- **Rotate app-specific passwords every 6 months**
- **Monitor Apple Developer Portal for unauthorized certificates**

Once you complete this setup, your CI/CD pipeline will be ready for secure, automated releases! 🚀

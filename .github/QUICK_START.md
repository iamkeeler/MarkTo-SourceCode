# 🎯 Quick Start: Configure GitHub Secrets

## Current Status: ✅ CSR Files Created

Your Certificate Signing Request files are ready at:
- `~/Desktop/MarkTo-Certificates/developer_id_application.csr`
- `~/Desktop/MarkTo-Certificates/developer_id_installer.csr`

## Next: Create Certificates in Apple Developer Portal

### Step 1: Create Developer ID Application Certificate

1. **Go to Apple Developer Portal:**
   ```
   https://developer.apple.com/account/resources/certificates/list
   ```

2. **Create Certificate:**
   - Click **"+ Add Certificate"**
   - Select **"Developer ID Application"** 
   - Click **"Continue"**

3. **Upload CSR:**
   - Upload: `~/Desktop/MarkTo-Certificates/developer_id_application.csr`
   - Click **"Continue"**

4. **Download Certificate:**
   - Download the `.cer` file
   - Save it as: `~/Desktop/MarkTo-Certificates/developer_id_application.cer`

### Step 2: Create Developer ID Installer Certificate

1. **In Apple Developer Portal:**
   - Click **"+ Add Certificate"** again
   - Select **"Developer ID Installer"**
   - Click **"Continue"**

2. **Upload CSR:**
   - Upload: `~/Desktop/MarkTo-Certificates/developer_id_installer.csr`
   - Click **"Continue"**

3. **Download Certificate:**
   - Download the `.cer` file  
   - Save it as: `~/Desktop/MarkTo-Certificates/developer_id_installer.cer`

## After Downloading Both Certificates:

### Option A: Run Automated Setup Script
```bash
cd /Users/iamkeeler/FileStorage/GitProjects/MarkConvert
./setup_certificates.sh
```

### Option B: Manual Setup

1. **Install Certificates:**
   ```bash
   cd ~/Desktop/MarkTo-Certificates
   security import developer_id_application.cer -k ~/Library/Keychains/login.keychain
   security import developer_id_application.key -k ~/Library/Keychains/login.keychain
   security import developer_id_installer.cer -k ~/Library/Keychains/login.keychain  
   security import developer_id_installer.key -k ~/Library/Keychains/login.keychain
   ```

2. **Verify Installation:**
   ```bash
   security find-identity -v | grep "Developer ID"
   ```
   Should show 2 certificates.

3. **Export as P12 Files:**
   - Open **Keychain Access**
   - Find **"Developer ID Application: Gary Keeler (TEAMID)"**
   - Right-click → **Export** → Save as `.p12` with password
   - Repeat for **"Developer ID Installer"**

4. **Convert to Base64:**
   ```bash
   base64 -i developer_id_application.p12 | pbcopy
   # Paste as DEVELOPER_ID_APPLICATION_P12 secret
   
   base64 -i developer_id_installer.p12 | pbcopy  
   # Paste as DEVELOPER_ID_INSTALLER_P12 secret
   ```

## Required GitHub Secrets

Go to: https://github.com/iamkeeler/MarkTo-SourceCode/settings/secrets/actions

Add these 7 secrets:

| Secret Name | How to Get |
|-------------|------------|
| `DEVELOPER_ID_APPLICATION_P12` | Base64 of application .p12 file |
| `DEVELOPER_ID_INSTALLER_P12` | Base64 of installer .p12 file |
| `CERT_PASSWORD` | Password you set for .p12 files |
| `KEYCHAIN_PASSWORD` | Any strong password (for CI/CD) |
| `APPLE_ID` | Your Apple Developer account email |
| `APPLE_ID_PASSWORD` | App-specific password from appleid.apple.com |
| `TEAM_ID` | 10-character team ID from developer.apple.com |

## Testing

After configuring secrets:

1. **Create test branch:**
   ```bash
   git checkout -b test-cicd
   echo "CI/CD test" >> README.md
   git add README.md
   git commit -m "Test CI/CD"
   git push origin test-cicd
   ```

2. **Create PR to release branch:**
   ```bash
   gh pr create --base release --title "Test CI/CD" --body "Testing secure pipeline"
   ```

3. **Merge PR and watch Actions tab**
4. **Approve deployment when prompted**
5. **Check for successful release creation**

## Need Help?

- Run the automated script: `./setup_certificates.sh`
- Check detailed guide: `.github/SECRETS_SETUP.md`
- Review security info: `.github/SECURITY_CHECKLIST.md`

The Apple Developer Portal should now be open in your browser. Follow the steps above to create your certificates! 🚀

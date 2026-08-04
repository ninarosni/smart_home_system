# iOS Build & Deployment Guide

Since this project is built with Flutter, you can generate an iOS app even if you don't own a Mac locally, thanks to GitHub Actions.

## 1. Automated Builds (GitHub Actions)
Every time you push code to the `main` branch of your GitHub repository, a "Virtual Mac" automatically builds the iOS app for you.

### How to download the build:
1. Go to your repository on GitHub.
2. Click on the **Actions** tab.
3. Select the latest successful "Build Apps" workflow run.
4. Scroll down to **Artifacts** and download `release-ios`.

## 2. Installing on a Physical iPhone
The build from GitHub Actions is **unsigned**. To install it on an iPhone, you have a few options:

### Option A: Using AltStore (Free, No Mac Needed)
AltStore expects a `.ipa` file. I've updated the automated build to provide this for you.

1. **Download the IPA**:
   - Go to GitHub Actions and download `release-ios`. 
   - Extract the zip to get `smart_home.ipa`.
2. **Transfer to iPhone**:
   - **Method 1 (iCloud/Google Drive)**: Upload the `.ipa` to your drive, then open the Drive app on your iPhone and save the file to the "Files" app.
   - **Method 2 (AirDrop/Cable)**: Send the file directly to your phone.
3. **Install in AltStore**:
   - Open the **AltStore** app on your iPhone.
   - Go to the **"My Apps"** tab.
   - Tap the **"+"** icon in the top-left corner.
   - Select the `smart_home.ipa` file you just saved to your phone.
   - If prompted, sign in with your Apple ID.
4. **Trust the App**:
   - Go to iPhone **Settings > General > VPN & Device Management**.
   - Tap on your Apple ID and select **"Trust"**.

*Note: You must refresh the app every 7 days via AltStore.*

### Option B: Local Build (Requires Mac & Xcode)
If you have access to a Mac:
1. Clone the repository.
2. Run `flutter pub get`.
3. Open `ios/Runner.xcworkspace` in Xcode.
4. Select your Team in "Signing & Capabilities."
5. Plug in your iPhone and click the **Run** button.

## 3. Firebase Configuration for iOS
In the app's **Settings** screen, ensure you provide:
- **API Key**
- **App ID**
- **iOS Bundle ID**: This must match the identifier set in your Firebase project (e.g., `com.example.smartHome`).

---

> [!TIP]
> For a permanent installation without a 7-day limit, an Apple Developer Program membership ($99/year) is required to sign the app for long-term use.

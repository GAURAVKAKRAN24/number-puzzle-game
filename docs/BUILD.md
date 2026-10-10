# Build and Export Guide: Number Merge Puzzle (Windows)

This guide provides beginner-friendly, step-by-step instructions to export debug APKs for local testing and signed release Android App Bundles (.aab) for Google Play.

---

## 1. Prerequisites and Toolchain

### A. Godot Engine 4.3 Stable
- Ensure Godot 4.3 Stable is downloaded and extracted.
- Location used in this project: `C:\Users\acer\godot\Godot_v4.3-stable_win64_console.exe` (or your preferred directory).

### B. Java Development Kit (JDK 17)
Android Gradle build tools for Godot 4.3 require OpenJDK 17:
1. Download Microsoft OpenJDK 17 or Eclipse Temurin JDK 17 for Windows x64:
   - Eclipse Temurin: `https://adoptium.net/temurin/releases/?version=17`
2. Install the MSI and make sure the installer option **"Set JAVA_HOME variable"** is enabled.
3. Verify in PowerShell:
   ```powershell
   java -version
   ```
   *(Should report `openjdk version "17.0.x"`)*

### C. Android Studio & Android SDK
1. Download and install Android Studio: `https://developer.android.com/studio`
2. Open Android Studio -> **More Actions** -> **SDK Manager**:
   - Under **SDK Platforms**, install **Android 16 (API 36)** and **Android 14 (API 34)**.
   - Under **SDK Tools**, check:
     - **Android SDK Build-Tools 34.0.0** (or 35/36)
     - **Android SDK Command-line Tools (latest)**
     - **Android SDK Platform-Tools**
     - **CMake (3.22.1)**
     - **NDK (Side by side) 23.2.8568313**
3. Note your SDK path (typically `C:\Users\<YourUsername>\AppData\Local\Android\Sdk`).

### D. Configure Godot Editor Settings
1. Open Godot Engine and open `Number Merge Puzzle`.
2. In the top menu, go to **Editor** -> **Editor Settings**.
3. In the left panel, scroll down to **Export** -> **Android**:
   - Set **Android SDK Path**: `C:/Users/<YourUsername>/AppData/Local/Android/Sdk`
   - Set **Java SDK Path** (or `JAVA_HOME`): `C:/Program Files/Eclipse Adoptium/jdk-17.x.x`

---

## 2. Godot Android Export Templates

1. Inside Godot, click **Editor** -> **Manage Export Templates...**.
2. Click **Download and Install** for Godot 4.3.
3. Wait for the download to complete (~800 MB).

---

## 3. Google AdMob Plugin Setup

The project is built with centralized AdMob management in `scripts/autoload/ad_manager.gd`, operating in a deterministic mock mode during development and on desktop.

To enable native Android ads in release:
1. Download the maintained **Poing Studios Godot AdMob Android Plugin** (Godot 4.x compatible):
   `https://github.com/poing-studios/godot-admob-android`
2. Place the addon in `res://addons/poing-godot-admob/`.
3. In Godot, go to **Project** -> **Project Settings** -> **Plugins** and enable `PoingGodotAdMob`.
4. In `export_presets.cfg` under `[preset.1.options]`, check the PoingGodotAdMob plugin checkbox.
5. In `res://scripts/autoload/ad_manager.gd`, replace the Google Test Ad Unit IDs with your production AdMob IDs once your account and app are approved.

---

## 4. Keystore Generation for Release Signing

> [!CAUTION]
> **Never commit your release keystore or passwords to Git!**
> The `.gitignore` is pre-configured to ignore all `*.keystore`, `*.jks`, and credential files.

Run this command in PowerShell to generate a 2048-bit RSA release signing key:

```powershell
keytool -genkey -v -keystore release.keystore -alias numbermerge -keyalg RSA -keysize 2048 -validity 10000
```
- You will be prompted to enter a keystore password (choose a secure password and record it in a password manager).
- Answer the organization questions (name, company, country).
- Back up `release.keystore` to an encrypted external drive or secure cloud vault. If you lose this key, you cannot update your game on Google Play!

---

## 5. Exporting Debug APK (For Local Device Testing)

### Method A: Via Godot Editor GUI
1. Open Godot -> **Project** -> **Export...**.
2. Select the **Android Debug** preset.
3. Check that the export path is `builds/NumberMergePuzzle-debug.apk`.
4. Click **Export Project...**.
5. Uncheck **Export With Debug** only if you want an unsigned release build; leave it checked for debug testing.
6. Click **Save**.

### Method B: Via PowerShell Command Line
```powershell
& "C:\Users\acer\godot\Godot_v4.3-stable_win64_console.exe" --headless --export-debug "Android Debug" builds/NumberMergePuzzle-debug.apk
```

### Installing on Device via ADB
1. Enable **Developer Options** and **USB Debugging** on your Android phone.
2. Connect your phone via USB.
3. Run:
   ```powershell
   adb install -r builds/NumberMergePuzzle-debug.apk
   ```

---

## 6. Exporting Signed Release AAB (For Google Play Store)

1. Open Godot -> **Project** -> **Export...**.
2. Select the **Android Release** preset.
3. In the right panel under **Keystore**:
   - **Release**: Path to your `release.keystore` file.
   - **Release User**: `numbermerge` (the alias you chose in `keytool`).
   - **Release Password**: The password you chose for the keystore.
4. Set export path to: `builds/NumberMergePuzzle-release.aab`.
5. Click **Export Project...**.
6. Ensure **Export With Debug** is **UNCHECKED**.
7. Click **Save**.

---

## 7. Troubleshooting Common Build Errors

### A. "Could not find Android SDK"
- Open **Editor -> Editor Settings -> Export -> Android** and verify the path uses forward slashes:
  `C:/Users/<Username>/AppData/Local/Android/Sdk`

### B. "Target API Level Mismatch"
- Google Play requires target API level 35 or 36.
- Check `export_presets.cfg` -> `gradle_build/target_sdk="36"`.
- Ensure SDK Manager has API level 36 installed.

### C. "Gradle Daemon Terminated" / Out of Memory
- Increase Gradle heap in Android build template:
  Create `android/build/gradle.properties` with:
  `org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m`

### D. AdMob App ID Missing from AndroidManifest
- When using the native AdMob plugin, ensure the App ID tag is present in the export preset's custom AndroidManifest or plugin settings:
  `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-3940256099942544~3347511713"/>`

# Google Play Store Release Checklist: Number Merge Puzzle

A comprehensive, beginner-friendly walkthrough for publishing Number Merge Puzzle on Google Play.

---

## Phase 1: Play Console & Account Preparation

1. **Google Play Console Account**:
   - Register at `https://play.google.com/console/signup` ($25 one-time registration fee).
   - Complete identity verification (D-U-N-S number for organizational accounts or government ID for personal accounts).
2. **Understand Closed Testing Policy for Personal Accounts**:
   - Google requires developers with personal accounts created after November 13, 2023 to run a closed test with at least **20 opted-in testers** for a minimum of **14 continuous days** before applying for production access.
   - Plan ahead by gathering family, friends, or beta testing groups.

---

## Phase 2: Project Configuration & Identity

1. **Select Final Application ID**:
   - In `export_presets.cfg`, update:
     ```ini
     package/unique_name="com.yourstudio.numbermerge"
     ```
     Change `com.yourstudio` to your verified reverse domain (e.g. `com.epicpuzzles.numbermerge`).
2. **Version Code Management**:
   - Set initial `version/code=1` and `version/name="1.0.0"`.
   - Each future update uploaded to Google Play must increment `version/code` monotonically (2, 3, 4...).
3. **Generate & Safeguard Release Keystore**:
   - Generate your keystore using `keytool` as documented in `docs/BUILD.md`.
   - Store your keystore and password in a secure password manager and offline encrypted backup.

---

## Phase 3: Store Listing Assets & Copy

1. **App Title**: `Number Merge Puzzle` (Under 30 characters).
2. **Short Description** (Under 80 characters):
   `Connect matching numbers, merge tiles, and test your brain in this sleek puzzle!`
3. **Full Description** (Under 4000 characters):
   ```
   Welcome to Number Merge Puzzle — an intuitive, satisfying, and minimalist 2D number-connecting challenge!

   HOW TO PLAY:
   - Drag across matching numbered tiles horizontally or vertically.
   - Connect 2 or more identical tiles to merge them into higher values!
   - Watch pairs of 2 become 4, 4 become 8, and race toward 2048 and beyond.
   - Plan your moves strategically to keep space open on the 5x5 board.
   - Challenge your high score and unlock vibrant milestone tiles!

   FEATURES:
   - 100% Offline Playable: Enjoy anywhere, anytime without an internet connection.
   - Smooth, Responsive Controls: Fluid drag-to-connect gestures with haptic feedback.
   - Clean Minimalist Aesthetics: Beautiful pastel colors and dark-mode elegance.
   - Procedural Audio: Crisp, low-latency chimes and soothing harmonic effects.
   - Completely Free: Play casually at your own pace with optional second chances!

   Can you reach 2048 and conquer the board? Download now and start merging!
   ```
4. **App Category & Tags**:
   - Category: `Games` -> `Puzzle`
   - Tags: `Puzzle`, `Brain Games`, `Casual`, `Offline`
5. **Store Graphics**:
   - **App Icon**: 512 x 512 px 32-bit PNG (`assets/icons/app_icon.png` provided).
   - **Feature Graphic**: 1024 x 500 px 24-bit PNG or JPEG (`assets/icons/feature_graphic.png` provided).
   - **Screenshots**: At least 4 screenshots (16:9 or 18:9 aspect ratio, minimum 1080px on shortest side). Take real gameplay screenshots from your test device.

---

## Phase 4: App Content & Declarations

Complete each section under **App Content** in the Play Console:

1. **Privacy Policy**:
   - Host `docs/PRIVACY.md` publicly (e.g., GitHub Pages, personal website, or public repository).
   - Paste the public HTTPS URL in the Play Console Privacy Policy field.
2. **Ads Declaration**:
   - Select **"Yes, my app contains ads"** (reflecting AdMob rewarded and natural break interstitials).
3. **App Access**:
   - Select **"All functionality is available without special access"** (no login or paywalls).
4. **Target Audience and Content**:
   - Target Age: **13 and older** (recommended for simplified COPPA/Families compliance).
   - Not appealing primarily to children under 13.
5. **Content Rating (IARC)**:
   - Complete the International Age Rating Coalition questionnaire:
     - Violence: None
     - Profanity: None
     - Simulated Gambling: None
     - Result: PEGI 3 / ESRB Everyone.
6. **Data Safety Form**:
   - Answer according to `docs/PRIVACY.md#section-5`:
     - Does your app collect or share user data? -> **Yes** (solely by AdMob SDK for advertising & diagnostics).
     - Is data encrypted in transit? -> **Yes** (HTTPS).
     - Can users request data deletion? -> **Yes** (in-game local reset button).

---

## Phase 5: Building & Uploading the Release AAB

1. Build the signed release AAB in Godot (`builds/NumberMergePuzzle-release.aab`) following `docs/BUILD.md`.
2. In Google Play Console -> **Testing** -> **Closed testing** (or Internal testing).
3. Click **Create new release**.
4. Enable **Play App Signing** (Google manages your app signing key).
5. Drag and drop `NumberMergePuzzle-release.aab`.
6. Add Release Notes:
   ```
   Initial release of Number Merge Puzzle!
   - 5x5 number connecting puzzle
   - Smooth drag controls and haptic feedback
   - High score tracking and offline play
   ```
7. Click **Next** -> **Review release** -> **Start rollout to closed testing**.

---

## Phase 6: Testing & Production Rollout

1. Invite your 20 testers to join via their Google Play accounts.
2. Ensure testers download and play the game across the 14-day testing window.
3. Review the **Pre-launch report** in Play Console:
   - Check automated device test results for crashes, ANRs, or UI anomalies.
4. After 14 days and active tester feedback, click **Apply for production access**.
5. Answer Google's production access questionnaire highlighting your testing methodology.
6. Once approved, initiate a **Staged Rollout** to Production:
   - Day 1: 10%
   - Day 3: 25% (monitor crash rate < 1.09% and ANR rate < 0.47%)
   - Day 5: 50%
   - Day 7: 100% full production rollout!

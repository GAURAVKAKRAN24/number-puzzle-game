# Number Merge Puzzle

A minimalist, vibrant, offline-first 2D number merge puzzle game for Android built with **Godot Engine 4.3 (GDScript)**.

![Number Merge Puzzle](assets/icons/feature_graphic.png)

## 🎮 How to Play

1. **Connect Matching Tiles**: Drag across 2 or more horizontally or vertically adjacent tiles with the same number.
2. **Orthogonal Only**: No diagonal merges allowed.
3. **Deterministic Math**: Selected tiles merge into the last tile touched, doubling in value:
   $$\text{ResultValue} = V \times 2^{N - 1}$$
4. **Anti-Deadlock Board**: New tiles spawn after every merge. Keep space open on the 5x5 board!
5. **High Score & Milestones**: Track your personal best and unlock celebratory milestones ($128, 256, 512, 1024, 2048, 4096$).

---

## 🚀 Features

- **100% Offline Playable**: Instant startup, no login, no backend server needed.
- **Pure Procedural Audio**: Low-latency synthesized sound effects (tap, scale notes, chord pings, fanfare).
- **Safe Persistence**: Atomic JSON save system with automatic corrupted data recovery.
- **Haptic Vibration**: Smooth tactile feedback on moves and merges.
- **Google AdMob Ready**: Non-intrusive frequency-capped natural break interstitials and rewarded second-chance revive with duplicate callback protection.
- **Automated CI/CD**: Automatic Android APK generation on GitHub Actions.

---

## 🛠️ Project Structure

```
res://
  project.godot
  export_presets.cfg
  .github/workflows/
    build_apk.yml       # GitHub Actions automated APK build
  scenes/
    splash.tscn         # Brand intro & resource setup
    main_menu.tscn      # Home screen (Play, Continue, Best Score, Settings)
    game.tscn           # 5x5 Board, touch drag input, score header
    settings.tscn       # Audio, music, vibration toggles & data reset
    components/
      tile.tscn
      board_cell.tscn
      pause_dialog.tscn
      confirmation_dialog.tscn
      how_to_play_dialog.tscn
      game_over_dialog.tscn
  scripts/
    autoload/
      audio_manager.gd
      save_manager.gd
      settings_manager.gd
      ad_manager.gd
    game_manager.gd
    grid_manager.gd
    score_manager.gd
    tile.gd
  tests/                # Automated test suite (21 passed tests)
    run_tests.gd
  docs/
    GAME_RULES.md
    ARCHITECTURE.md
    BUILD.md
    TESTING.md
    PRIVACY.md
    RELEASE_CHECKLIST.md
```

---

## 🧪 Running Tests Locally

Run the complete test suite headlessly via Godot 4.3:

```bash
godot --headless --path . -s tests/run_tests.gd
```

---

## 📦 Download APK via GitHub Actions

Every push to this repository triggers an automated Android APK build:
1. Go to the **Actions** tab in this GitHub repository.
2. Click on the latest **Build Android APK** workflow run.
3. Download the **`NumberMergePuzzle-debug-apk`** artifact at the bottom of the page.
4. Extract the `.zip` and install the `.apk` on any Android device!

---

## 📄 License
MIT License.

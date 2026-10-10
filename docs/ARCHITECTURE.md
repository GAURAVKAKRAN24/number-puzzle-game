# Architecture & System Design: Number Merge Puzzle

## 1. Architectural Overview
Number Merge Puzzle follows Godot 4 best practices:
- **Separation of Concerns**: Game logic is completely decoupled from UI presentation.
- **Event-Driven**: Components communicate via typed Godot Signals; managers do not couple to concrete UI node paths.
- **Single Source of Truth**: `GridManager` owns the 5x5 board state array. `ScoreManager` owns scores. `SaveManager` owns disk persistence. `GameManager` coordinates the lifecycle state machine.
- **Lightweight 2D**: Pure native Godot 2D CanvasItem rendering, responsive Control anchors, and vector/procedural styles for minimal APK footprint (<25 MB).

## 2. Directory Structure
```
res://
  project.godot
  export_presets.cfg
  scenes/
    splash.tscn
    main_menu.tscn
    game.tscn
    settings.tscn
    game_over.tscn
    components/
      tile.tscn
      board_cell.tscn
      pause_dialog.tscn
      confirmation_dialog.tscn
      how_to_play_dialog.tscn
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
    board_cell.gd
  assets/
    icons/
      app_icon.png
      adaptive_foreground.png
      adaptive_background.png
    audio/
      (synthesized/procedural SFX generator fallback)
  tests/
    test_grid_logic.gd
    test_score_manager.gd
    test_save_corruption.gd
    test_ad_manager.gd
    run_tests.gd
  docs/
    ARCHITECTURE.md
    GAME_RULES.md
    BUILD.md
    TESTING.md
    PRIVACY.md
    RELEASE_CHECKLIST.md
```

## 3. Finite State Machine
The game operates under an explicit state enum in `GameManager`:
```
enum State {
    MENU,
    PLAYING,
    ANIMATING,
    PAUSED,
    GAME_OVER
}
```

Transitions:
- `MENU -> PLAYING`: On New Game or Continue.
- `PLAYING -> ANIMATING`: When player completes a valid drag merge; user input is temporarily locked.
- `ANIMATING -> PLAYING`: When merge animation and tile spawn finish.
- `ANIMATING -> GAME_OVER`: When merge/spawn resolves and no moves remain with a full board.
- `PLAYING -> PAUSED`: When pause button is tapped or Android lifecycle pause/background occurs.
- `PAUSED -> PLAYING`: When resumed.
- `PAUSED -> MENU`: When quit confirmed.
- `GAME_OVER -> PLAYING`: On Play Again or Second Chance revived.
- `GAME_OVER -> MENU`: On Return Home.

## 4. Manager Responsibilities
1. **GameManager**: Controls the active lifecycle state, coordinates scene transitions, and handles Android back navigation.
2. **GridManager**: Pure data and validation logic for the 5x5 grid:
   - Validates coordinate bounds.
   - Validates horizontal/vertical orthogonal adjacency.
   - Validates equal tile values along chains.
   - Executes deterministic merge math: $V \times 2^{N-1}$.
   - Finds available empty cells and spawns new tiles.
   - Detects Game Over (board full + zero valid orthogonal pairs).
3. **ScoreManager**:
   - Calculates score additions: $\text{ResultValue} \times N$.
   - Tracks current score and best score.
   - Emits signals when score updates or high score is broken.
4. **SaveManager (Autoload)**:
   - Stores active board state, score, best score, highest tile in `user://game_save.json`.
   - Validates schema on load (versioning, types, dimensions).
   - Detects corrupt JSON or invalid values and gracefully restores defaults without crashing.
   - Provides safe atomic write via temporary file swap to prevent data corruption if app is killed during save.
5. **SettingsManager (Autoload)**:
   - Stores audio mute, vibration/haptics toggle in `user://settings.json`.
   - Dispatches audio/vibration events.
6. **AdManager (Autoload)**:
   - Isolates Google AdMob integration.
   - Gracefully falls back to mock/stub mode in editor and desktop environments or when AdMob plugin is not loaded.
   - Frequency caps interstitials (shown only after game over, never in gameplay).
   - Verifies reward completion callbacks before granting game revives.
7. **AudioManager (Autoload)**:
   - Plays clean synthesized audio cues for tap, select, merge, milestone, game over.
   - Respects settings mute states.

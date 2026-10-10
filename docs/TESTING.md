# Testing Plan and Verification Report: Number Merge Puzzle

## 1. Automated Test Suite

The project includes headless unit and integration tests covering core game mechanics, deterministic mathematical algorithms, data schema validation, corruption recovery, and advertising logic.

### How to Run Automated Tests
Execute the test runner via the Godot 4 console executable:
```powershell
& "C:\Users\acer\godot\Godot_v4.3-stable_win64_console.exe" --headless --path . -s tests/run_tests.gd
```

### Verified Test Results (Executed on 2026-10-10)
| Test Suite | Test Case | Status | Details |
|---|---|---|---|
| **Scene Integrity** | `scenes/splash.tscn` | **PASS** | Valid packed scene & clean instantiation |
| **Scene Integrity** | `scenes/main_menu.tscn` | **PASS** | Responsive layout & button tree verified |
| **Scene Integrity** | `scenes/settings.tscn` | **PASS** | Settings toggles and dialog nodes verified |
| **Scene Integrity** | `scenes/game.tscn` | **PASS** | 5x5 board, Line2D, score cards, dialogs verified |
| **Scene Integrity** | `scenes/components/*.tscn` | **PASS** | Tile, cell, pause, confirm, game over dialogs |
| **Grid Logic** | `test_initial_grid` | **PASS** | Exactly 6 initial tiles spawned, 19 empty cells |
| **Grid Logic** | `test_valid_merge_powers_of_two` | **PASS** | $2+2 \rightarrow 4$, $4+4+4 \rightarrow 16$; origin tiles cleared |
| **Grid Logic** | `test_reject_unequal_tiles` | **PASS** | Chaining unequal numbers (2 and 4) is rejected |
| **Grid Logic** | `test_reject_diagonal_tiles` | **PASS** | Strictly prohibits diagonal connections |
| **Grid Logic** | `test_reject_duplicate_coords` | **PASS** | Self-intersecting selection loops are rejected |
| **Grid Logic** | `test_board_full_and_game_over` | **PASS** | Alternating full board triggers game over; adjacent pairs prevent it |
| **Grid Logic** | `test_revive_lowest_tiles` | **PASS** | Second chance clears exactly 3 lowest tiles |
| **Score Manager** | `test_point_calculations` | **PASS** | Deterministic score formula: $\text{Points} = \text{Result} \times N$ |
| **Score Manager** | `test_high_score_tracking` | **PASS** | Best score updates dynamically on record break |
| **Score Manager** | `test_score_reset` | **PASS** | Current score resets to 0; best score preserved |
| **Persistence** | `test_valid_save_load` | **PASS** | Board array and score roundtrip accurately |
| **Persistence** | `test_corrupted_json_recovery` | **PASS** | Truncated/corrupt JSON recovers safely without crash |
| **Persistence** | `test_invalid_schema_recovery` | **PASS** | Incomplete dimensions/negative scores rejected |
| **Ad Manager** | `test_admob_test_ids` | **PASS** | Standard Google AdMob test IDs match exactly |
| **Ad Manager** | `test_reward_double_callback` | **PASS** | Duplicate SDK callbacks cannot grant double revives |
| **Ad Manager** | `test_interstitial_capping` | **PASS** | Interstitials capped at 1 per 3 games & 90s delay |

**Total Automated Tests**: 21 passed, 0 failed.

---

## 2. Manual Android QA Checklist

Before public release on Google Play, perform manual testing on at least two physical Android devices (one modern phone, one entry-level/older phone):

### A. Installation and Launch
- [ ] Debug APK installs successfully via `adb install -r`.
- [ ] App launches smoothly without hanging on the splash screen.
- [ ] Application title and launcher icon display correctly on the home screen.

### B. Core Gameplay Experience
- [ ] Dragging horizontally and vertically connects equal tiles with a visible glow line.
- [ ] Backtracking touch deselects the most recent tile smoothly.
- [ ] Releasing touch executes the merge pop animation, sound effect, and haptic vibration.
- [ ] Newly spawned tiles pop onto empty board spaces.
- [ ] Rapid tapping and frantic gestures do not cause duplicate input or state corruption.
- [ ] Reaching a milestone (128, 256, 512, etc.) displays the celebration banner.

### C. Dialogs & Navigation
- [ ] Pause button opens the Pause dialog; gameplay input is blocked while paused.
- [ ] Restart button triggers confirmation dialog to prevent accidental data loss.
- [ ] Android physical / gesture "Back" button pauses the game during play and closes open dialogs.
- [ ] Returning to Main Menu persists the active board; "Continue" button becomes visible.

### D. Settings & Audio
- [ ] Toggling "Sound Effects" OFF immediately mutes all tap, merge, and chime sounds.
- [ ] Toggling "Haptic Vibration" OFF disables handheld vibration.
- [ ] "Reset All Saved Data" clears high score and board state after confirmation.

### E. Lifecycle & Hardware Handling
- [ ] Backgrounding the app (Home button or switching apps) pauses the game and halts audio.
- [ ] Returning to the app restores the exact board state without stutter.
- [ ] Device rotation does not alter portrait orientation (orientation locked to portrait).
- [ ] UI scales correctly on tall 20:9 aspect ratios, compact 16:9 phones, and punch-hole notch displays.

### F. Offline & Ad Resiliency
- [ ] Activating Airplane Mode allows full, uninterrupted offline gameplay.
- [ ] When offline, tapping "Watch Ad" for Second Chance displays a polite "Ad unavailable" message or gracefully continues without hanging.
- [ ] Reconnecting to Wi-Fi restores test ad availability.

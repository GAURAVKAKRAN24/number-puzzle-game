# Game Rules Specification: Number Merge Puzzle

## 1. Overview
"Number Merge Puzzle" is a minimalist, colorful 2D number-merging puzzle game played on a 5x5 grid in portrait orientation. The core loop consists of connecting adjacent matching numbered tiles, merging them into higher-power tiles, maintaining board space, and chasing high scores.

## 2. Board Layout
- **Dimensions**: 5 rows × 5 columns = 25 total cells.
- **Coordinates**: `(x, y)` where `0 <= x < 5` and `0 <= y < 5`.
- **Tile State**: Each cell either contains a tile with a positive power-of-two value (`2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096...`) or is empty (`null` / 0).

## 3. Initial Setup
- The game starts with **6 tiles** placed at distinct, randomly chosen empty cells on the 5x5 grid.
- **Initial Value Distribution**:
  - `2`: 75% probability
  - `4`: 25% probability
- The player begins with a score of 0.

## 4. Selection Mechanics
- **Interaction**: The player selects tiles by dragging across adjacent tiles or tapping a valid sequence.
- **Adjacency**: Orthogonal only (horizontal and vertical: `dx = 0, |dy| = 1` OR `|dx| = 1, dy = 0`). **Diagonal selections are strictly prohibited**.
- **Equivalence**: All tiles in a selected chain must have the **exact same value** ($V$).
- **Chain Length ($N$)**: A valid merge requires at least 2 tiles ($N \ge 2$).
- **No Self-Intersection**: A cell cannot appear more than once in the same selection chain.
- **Path Backtracking**: If the player drags back to the immediately preceding tile in the chain, the most recent tile is deselected (standard intuitive undo during drag).

## 5. Merging Rule (Deterministic)
When the player releases touch on a valid chain of $N \ge 2$ tiles of value $V$:
1. **Destination Tile**: The **last tile** in the selection sequence is designated as the target/merge destination.
2. **Result Value**:
   $$\text{ResultValue} = V \times 2^{N - 1}$$
   - Example 1: Two tiles of value 2 ($N=2, V=2$) $\rightarrow 2 \times 2^1 = 4$.
   - Example 2: Three tiles of value 2 ($N=3, V=2$) $\rightarrow 2 \times 2^2 = 8$.
   - Example 3: Two tiles of value 512 ($N=2, V=512$) $\rightarrow 512 \times 2^1 = 1024$.
3. **Tile Removal**: All other $N-1$ tiles in the selection sequence are cleared from the board.
4. **Target Update**: The target cell value is updated to $\text{ResultValue}$ and triggers a merge pop animation, haptic vibration, and sound.

## 6. Score Calculation
- For each successful merge:
  $$\text{PointsAwarded} = \text{ResultValue} \times N$$
- `CurrentScore += PointsAwarded`.
- If `CurrentScore > BestScore`, `BestScore` is updated immediately and persisted.
- Scores are strictly non-negative 64-bit integers and cannot overflow under standard play.

## 7. Spawning Mechanics
1. Immediately after a merge completes:
   - Exactly **1 new tile** spawns in a randomly selected unoccupied cell.
   - **Spawn Value Weights**:
     - If highest tile on board $< 128$:
       - `2`: 70%
       - `4`: 30%
     - If highest tile on board $\ge 128$:
       - `2`: 60%
       - `4`: 30%
       - `8`: 10%
2. **Anti-Deadlock Rule**:
   - If after spawning, no valid adjacent moves exist on the board and empty cells still remain:
     - The game automatically spawns an additional tile into an empty cell (up to 2 extra attempts) to ensure continued playability when the board is not full.

## 8. Game Over Condition
The game ends when **both** of the following conditions are simultaneously met:
1. **No empty cells remain** on the 5x5 board (all 25 cells occupied).
2. **No valid moves remain**: No two horizontally or vertically adjacent cells contain the same value.

When Game Over is triggered:
- The board locks against further touch input.
- The Game Over screen displays the final score and best score.
- The player can choose:
  - **Play Again** (restarts clean board).
  - **Home** (returns to main menu).
  - **Second Chance (Rewarded Ad)**: Clears 3 lowest-value tiles to free space and allows the game to continue once per session.

## 9. Challenge / Milestone Progression
- As the player creates milestone tiles (`128, 256, 512, 1024, 2048, 4096`), milestone celebrations appear on screen.
- Current highest tile reached is tracked in local save data.

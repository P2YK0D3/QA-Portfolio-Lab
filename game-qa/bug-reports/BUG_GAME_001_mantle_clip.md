# [BUG-GAME-001] [Physics/Traversal] Mantling broken stone wall in Courtyard forces player collision through world mesh into infinite fall

- **Bug ID:** BUG-GAME-001
- **Severity:** Major (Progression blocker for current run; requires checkpoint reload or death trigger)
- **Priority:** High / P2
- **Component:** Traversal / Mantle Mechanics / Collision
- **Platform:** PC (Steam / Windows 11 64-bit)
- **Hardware Profile:** Intel Core i7 / 16GB RAM / RTX 3050 / Display: 1920x1080 Borderless Window
- **Build / Changelist:** Dev_QA_Build_v0.9.4_CL59102
- **Reproduction Rate:** 4/5 (80%)

---

### In-Engine Coordinates & Transform
- **Level / Map:** `MAP_Crypt_Courtyard_P`
- **Location Coordinates:** `X: 12480.32, Y: -8412.18, Z: 412.50`
- **Camera Angles:** `Pitch: -12.4°, Yaw: 144.8°, Roll: 0.0°`
- **Asset Name:** `SM_Ruin_StoneWall_Corner_02B`

---

### Preconditions
1. Load save at `Checkpoint_Courtyard_Entrance`.
2. Character agility attribute $\ge 10$ (enables high-speed sprint-mantle perk).
3. Frame rate uncapped (tested at ~75–90 FPS).

---

### Steps to Reproduce
1. From the courtyard fountain, sprint toward the crumbled stone wall in the northwest corner (`Yaw ~145°`).
2. Jump while holding sprint within 1 meter of the low-crumpled section of the wall.
3. Immediately press and hold the **Mantle / Climb** button (`Spacebar` / Gamepad `Cross/A`).
4. Observe character animation transition and collision capsule behavior during the mantle peak.

---

### Expected Result
- The character's collision capsule snaps to the top ledge surface of `SM_Ruin_StoneWall_Corner_02B`.
- The mantle animation completes, and the character stands upright on top of the wall geometry.

---

### Actual Result
- At frame 18 of `AM_Mantle_High_Ledge`, the root motion pushes the character collision capsule forward through the uncollided interior vertex seam of the wall.
- The player character phases completely through the exterior wall mesh and enters the unrendered void beneath the level.
- The character loops in the `Falling_Idle` animation for ~25 seconds before hitting the fallback kill z-volume (`KillZ: -5000.00`).

---

### Visual Evidence & Logs
- **Video Capture:** `captures/Courtyard_Mantle_Clip_Repro.mp4` (Recorded with `Show Collision` and `Stat FPS` active).
- **Wireframe Screenshot:** `captures/SM_Ruin_StoneWall_Wireframe_Gap.png` (Highlights missing collision hull on back-face polygons).
- **Session Log:** `game-qa/crash-analysis/Courtyard_Traversal_Session.log`.

---

### Suspected Root Cause
`SM_Ruin_StoneWall_Corner_02B` uses complex mesh-as-simple collision without a closed back-face hull. When root motion from `AM_Mantle_High_Ledge` applies forward velocity at $> 60\text{ fps}$, the capsule overlaps the single-sided polygon face before continuous collision detection (CCD) resolves the impact.

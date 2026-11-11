# Technical Compliance Matrix: Sony TRC & Microsoft TCR

**Document Reference**: `COMP-MATRIX-V2.6`  
**Target Platforms**: PlayStation 5 (SDK 9.00+) | Xbox Series X\|S (GDK Oct 2024+)  
**Evaluation Scope**: First-Party Platform Certification Pass & Release Readiness  
**Maintained By**: Lead Game Compliance QA  
**Last Audit Date**: 2026-11-10  

---

## 1. Compliance Certification Overview
First-party certification failure halts release and incurs substantial re-submission fees and timeline delays. This matrix consolidates Sony Technical Requirements Checklist (**TRC**) and Microsoft Technical Compliance Requirements (**TCR**) into a unified verification protocol for build signing.

---

## 2. Master Compliance Verification Matrix

| Req Area | Sony TRC Ref | MS TCR Ref | Requirement Description | Verification Procedure | Build Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Input** | `TRC R4053` | `TCR 0041` | **Controller Disconnection**<br>When the active controller disconnects during interactive gameplay, the title must automatically pause and display an appropriate system modal prompt. | Disconnect battery/USB cable during single-player action sequence. Verify pause state triggers immediately without unhandled null pointer or game world tick. | **PASS** |
| **Input** | `TRC R4056` | `TCR 0043` | **Controller Reassignment**<br>Title must detect when a user switches to a different physical gamepad or reassigns controller slots. | Connect second controller, reassign primary user via OS menu, return to game. Verify input routing adapts seamlessly. | **PASS** |
| **Save Data** | `TRC R4015` | `TCR 0064` | **Save Data Quota & Corrupt Data Handling**<br>Title must respect maximum save storage quotas and gracefully handle damaged/corrupted save files without crashing. | Inject randomized bit flips into `.sav` file on devkit drive. Launch game and select "Load Game". Title must present non-fatal error dialog ("Save data damaged") and allow starting new game. | **PASS** |
| **Save Data** | `TRC R4017` | `TCR 0066` | **Interrupted Save Integrity**<br>Cutting power or terminating process during an active save operation must not permanently corrupt previous valid save states. | Force terminate game process via DevKit Target Manager exactly during the disk write callback. Verify rollback to pre-existing save slot. | **PASS** |
| **User Identity** | `TRC R4024` | `TCR 0012` | **User Profile Switching**<br>When active user signs out via system dashboard, title must exit current session, return to title screen, and clear user-specific cached telemetry. | In active game, press Home button -> Switch Profile -> Select secondary gamertag. Verify session cleanup, inventory reset, and correct profile greeting. | **PASS** |
| **Power State** | `TRC R4082` | `TCR 0070` | **Suspend / Resume & Rest Mode**<br>Title must survive low-power Rest Mode (PS5) and Quick Resume (Xbox Series X) without audio desync, network deadlocks, or asset memory leaks. | Enter Rest Mode / Switch to another game for 30 minutes, resume title. Verify frame pacing, audio stream restoration, and socket reconnect logic. | **PASS** |
| **Branding** | `TRC R4001` | `TCR 0001` | **Platform Terminology Integrity**<br>All UI text, tutorials, and prompts must strictly match platform-sanctioned naming conventions (No Xbox terms on PS5, no generic button glyphs). | Run automated OCR / regex string audit against localized localization table for blacklisted terms. | **PASS** |
| **Achievements** | `TRC R4067` | `TCR 0090` | **Trophy / Achievement Unlock Sync**<br>Unlocks must be granted immediately upon meeting condition; offline earned trophies must synchronize cleanly on next network connection. | Unlock achievement with network disabled (DevKit offline mode). Re-enable network. Verify local cache flushes to Sony/Xbox cloud backend. | **PASS** |

---

## 3. Platform Terminology Guidelines (Audit Reference)

Any mismatch in nomenclature is an automatic certification rejection.

| Generic Concept | Sony PlayStation 5 Standard | Microsoft Xbox Series Standard | Rejection Example |
| :--- | :--- | :--- | :--- |
| Primary Input Device | DualSense Wireless Controller | Xbox Wireless Controller | "Press A on your controller" (on PS5) |
| Confirm Button | Cross Button (`Cross` symbol) | `A` Button | "Press [X] to continue" |
| Back / Cancel Button | Circle Button (`Circle` symbol) | `B` Button | "Press [Circle] to cancel" (on Xbox) |
| System Pause Button | Options Button | Menu Button | "Press Start" |
| Low Power State | Rest Mode | Standby / Instant-On | "Game paused during Sleep Mode" |
| Reward Unit | Trophy (Bronze/Silver/Gold/Platinum) | Achievement (Gamerscore / G) | "Achievement Unlocked!" (on PS5) |
| System Storage | Console Storage | Internal Storage / Expansion Card | "Hard Drive Full" |

---

## 4. Edge-Case Test Scenarios & Pass Protocols

### Scenario A: Xbox Quick Resume with Active Multiplayer Matchmaking
- **Action**: While in matchmaking queue, user switches to another heavy title (e.g., *Forza Horizon*), forcing the game into Quick Resume cache on NVMe. Return to game after 15 minutes.
- **Pass Criteria**: Title must detect socket timeout, gracefully notify the user ("Session timed out"), clear the stale matchmaking state, and avoid infinite spinner or thread deadlock.

### Scenario B: PS5 DualSense Adaptive Trigger Force Feedback Safety
- **Action**: Weapon jam sequence with high trigger resistance motor active. User simultaneously pulls trigger and triggers console power off.
- **Pass Criteria**: Haptic and adaptive trigger actuator motors must return to zero tension immediately to prevent hardware strain.

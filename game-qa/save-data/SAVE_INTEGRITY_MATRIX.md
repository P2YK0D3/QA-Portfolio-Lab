# Test Matrix: Save Game Integrity & Data Deserialization

- **Target Build:** `v0.9.4_dev`
- **Module:** Serialization / SaveGame Subsystem
- **Standard Reference:** Sony TRC R4041 / MS TCR 024 (Graceful Corruption Handling)

---

| Test ID | Test Target | Modification Applied | Expected Behavior | Actual Behavior | Result |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_SAV_01** | **Integer Overflow** | Set `currency.gold` = `999999999999` | Value clamped to `999,999` cap; no negative rollover. | Value clamped to `999,999`. | **PASS** |
| **TC_SAV_02** | **Negative Boundary** | Set `player.current_health` = `-100` | Engine auto-corrects to 1 HP or triggers respawn checkpoint. | Character spawned dead with black screen; requires reload. | **FAIL** (Logged BUG-GAME-205) |
| **TC_SAV_03** | **Malformed Syntax** | Truncated trailing `}` in JSON save | Displays clean *"Corrupt Save Detected"* dialog; falls back to backup slot. | System displayed prompt and restored backup. | **PASS** |
| **TC_SAV_04** | **Null Quest Flag** | Set `current_active_quest` = `null` | Game defaults to latest unlocked main story quest or shows warning. | CTD on load: Null reference in `QuestManager.cpp:88`. | **FAIL** (Logged BUG-GAME-206) |

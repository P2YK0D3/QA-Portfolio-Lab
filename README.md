# QA & Game QA Technical Portfolio Lab

A dual-track technical portfolio demonstrating hands-on competencies for **Junior Software QA (Manual/API/DB)** and **Junior Game QA (Engine/Physics/Compliance)** positions.

All test suites, bug tickets, API collections, and diagnostic investigations were designed, executed, and documented locally inside VS Code.

---

## 📁 Repository Architecture

```text
QA-Portfolio-Lab/
├── software-qa/
│   ├── test-suites/
│   │   └── TS_AUTH_CHECKOUT.md          # Multi-condition BVA, Happy Path, and Security Matrix
│   ├── api-collections/
│   │   └── ecommerce_postman_collection.json # Automated Postman test collection (200, 201, 404, 401)
│   ├── database-validation/
│   │   └── db_verification_tests.sql     # Multi-table SQL validation, JOIN integrity & duplicate detection
│   └── bug-reports/
│       └── BUG_SOFT_001_idempotency.md  # Race condition & payment double-charge defect report
│
└── game-qa/
    ├── compliance-checklists/
    │   └── TRC_TCR_matrix.md             # Sony TRC / Microsoft TCR console certification standards
    ├── crash-analysis/
    │   ├── UE5_BossEncounter_Crash.log   # Raw UE5 engine crash log (OOM & null asset allocation)
    │   └── CRASH_ANALYSIS_BOSS_OOM.md    # Root cause analysis & stack trace breakdown
    ├── save-data/
    │   ├── save_slot_01.json             # Serialized save game data structure
    │   └── SAVE_INTEGRITY_MATRIX.md      # Integer overflow, corruption, and boundary test matrix
    └── bug-reports/
        └── BUG_GAME_001_mantle_clip.md   # 3D spatial collision bug report with world coordinates

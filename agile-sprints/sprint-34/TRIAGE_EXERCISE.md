# Defect Triage Decision Matrix

### Incoming Incident:
*Title:* User Auth token expires after 60 seconds instead of 24 hours.

### Triage Evaluation Steps:
1. **Assess Severity:** Blocker (Affects 100% of active web and game players).
2. **Assess Priority:** P1 - Immediate Hotfix.
3. **Sprint Impact:**
   - In Scrum, you cannot simply add work to an active sprint without team agreement.
   - Action: Alert the Scrum Master & Product Owner.
   - Trade-off decision: Pull `QA-TASK-01` (Regression Matrix) out of Sprint 34 and push it to Sprint 35 backlog to accommodate testing the emergency hotfix for `BUG-3401`.

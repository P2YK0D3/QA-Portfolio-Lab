# Crash Investigation: OOM Crash on Phase 2 Boss Transition (UE5)

- **Target Build:** `v0.8.2_dev_CL49210`
- **Component:** Boss AI / Memory Management
- **Crash Category:** Fatal Crash to Desktop (CTD) - Out of Memory (OOM)

---

### Summary
When crossing `Trigger_Boss_Room_03` into the Phase 2 encounter, the client hard-crashes to desktop due to a failure in `FMallocBinned2::Allocate()` triggered by `ABossCharacter::SpawnPhase2Minions()`.

### Root Cause Signals (Extracted from Logs)
1. **Critical Failure:** `GenericPlatformMemory.cpp:241` throws out-of-memory error attempting to allocate 8MB with only 14MB physical memory remaining.
2. **Immediate Trigger:** `USkeletalMeshComponent::InitLODInfos()` called directly by `SpawnPhase2Minions()`.
3. **Asset Warnings:** Prior to the crash, missing audio asset `Roar_02.wav` and an empty animation sequence in `BS_Boss_Phase2` (slot 3) were flagged.

### Recommended Next Steps for Engineering
- Verify whether `SpawnPhase2Minions()` is instantiating unoptimized LOD0 meshes without garbage-collecting Phase 1 assets.
- Tech Art / Audio: Restore missing `Roar_02.wav` to project packaging to avoid asset load stalls.

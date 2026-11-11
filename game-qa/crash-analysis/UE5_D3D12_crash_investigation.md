# Unreal Engine 5 Crash Investigation: D3D12 Device Hung (`DXGI_ERROR_DEVICE_HUNG`)

**Incident Reference**: `CRASH-UE5-D3D12-088`  
**Engine Version**: Unreal Engine 5.4.2 (Custom Source Build)  
**Graphics API**: DirectX 12 (`D3D12RHI` / Shader Model 6.6)  
**Target Architecture**: PC (Windows 11 x64, DirectX Agility SDK 1.613.3)  
**Hardware Platforms Tested**:
- GPU A: NVIDIA GeForce RTX 4080 (16GB VRAM, Driver 555.99)
- GPU B: AMD Radeon RX 7900 XTX (24GB VRAM, Adrenalin 24.5.1)  
**Investigator**: Lead Engine & Performance QA Engineer  
**Date**: 2026-11-10  

---

## 1. Executive Summary
During high-speed level streaming transitions into map zone `LV_AncientForest_P`, the game triggers a fatal crash back to desktop within 1.5 to 4 seconds of entering the sub-level. The crash reporter outputs `DXGI_ERROR_DEVICE_HUNG` resulting from a Windows GPU TDR (Timeout Detection and Recovery) event. 

Deep diagnostic triage utilizing **NVIDIA Nsight Aftermath** and Unreal Engine **D3D12 Breadcrumb Markers** isolates the fault to an unconstrained compute shader dispatch during Nanite cluster rasterization compounded by an asynchronous compute fence race condition.

---

## 2. Crash Diagnostics & Callstack

### Unreal Engine Crash Reporter Dialog
```text
Fatal error: [File:D:\UE5_Engine\Engine\Source\Runtime\D3D12RHI\Private\D3D12Util.cpp] [Line: 873] 
CurrentQueue.Device->GetDeviceRemovedReason() failed 
 at D:\UE5_Engine\Engine\Source\Runtime\D3D12RHI\Private\D3D12Submission.cpp:946 
 with error DXGI_ERROR_DEVICE_HUNG (0x887A0006).
```

### Native Debugger Callstack (Visual Studio 2022 / PDBs loaded)
```text
> D3D12Core.dll!00007ff91a2e38c4()
  D3D12RHI.dll!D3D12RHI::VerifyD3D12Result(HRESULT Result, const char * Code, const char * Filename, unsigned int Line, FD3D12Device * Device) Line 873
  D3D12RHI.dll!FD3D12DynamicRHI::CheckForDeviceRemoved(bool bForce) Line 946
  D3D12RHI.dll!FD3D12CommandQueue::ExecuteCommandLists(TArray<FD3D12CommandListHandle> & CommandLists) Line 388
  Renderer.dll!Nanite::FRasterizePass::Execute(FRHICommandList & RHICmdList) Line 1420
  Renderer.dll!Nanite::IRenderer::Render(FRDGBuilder & GraphBuilder, FSceneRenderer & SceneRenderer) Line 412
  Renderer.dll!FDeferredShadingSceneRenderer::Render(FRDGBuilder & GraphBuilder) Line 2180
  Engine.dll!FRendererModule::BeginRenderingViewFamilies() Line 4821
```

---

## 3. GPU Breadcrumbs & Aftermath Crash Dump Analysis

By compiling with `-d3d12breadcrumbs` and analyzing the resulting `.nv-gpudmp` in NVIDIA Nsight Aftermath:

```text
[Active Context: AsyncComputeQueue_0]
  ├── Marker: SceneRendering
  │   ├── Marker: NaniteVisibilityCulling
  │   ├── Marker: NaniteClusterCullRasterize [ACTIVE AT TDR HANG]
  │   │   ├── Sub-pass: SoftwareRasterizeComputePass
  │   │   └── Thread Dispatch: (X: 1024, Y: 1024, Z: 64) -> Loop execution exceeded 2000ms watchdog threshold
[Graphics Queue: DirectQueue_0]
  └── Waiting on Fence: 0x000001FB882E10 (Signaled by AsyncComputeQueue_0) -> DEADLOCK
```

### Key Findings
1. **Compute Dispatch Loop Overrun**: The compute shader `NaniteRasterize.usf` received an unbounded cluster buffer of over $4.2 \times 10^6$ micro-triangles in a single frame due to a camera teleportation artifact where Level of Detail (LOD) distance culling was bypassed for one tick.
2. **Resource Barrier Conflict**: A UAV (Unordered Access View) transition on the `Nanite.RasterizerPageBuffer` was attempted by the Direct Queue before the Async Compute Queue flushed its write barrier, creating a driver-level queue stall.
3. **Windows TDR Trigger**: The Windows OS watchdog timed out after 2 seconds (`TdrDelay = 2`), marking the adapter as non-responsive and resetting the D3D12 device.

---

## 4. Steps to Reproduce
1. Launch game with editor or cooked build using CLI arguments:  
   `-dx12 -d3d12breadcrumbs -novsync`
2. Open console and run level load:  
   `open LV_AncientForest_P`
3. Execute camera trigger script simulating player respawn / cutscene skip:  
   `teleport -12450 88200 4500` (Dense foliage forest zone with ~18,000 instanced Nanite static meshes).
4. **Result**: Display freezes for 2 seconds, audio loops, engine exits with `DXGI_ERROR_DEVICE_HUNG`. Repro rate: **10/10 (100%)**.

---

## 5. Root Cause & Solution Verification

### Immediate Console Variable Mitigation (Temporary Workaround)
Running the following cvars in `DefaultEngine.ini` prevents the crash by constraining cluster allocations and routing Nanite through the graphics pipeline:
```ini
[SystemSettings]
; Cap max Nanite software rasterizer allocation
r.Nanite.MaxNodes=1048576
r.Nanite.MaxCandidateClusters=2097152
; Force single queue synchronization to prevent async compute deadlock
r.Nanite.AsyncRasterize=0
```

### Engineering Fix (Code Review & Merge)
The rendering team merged PR `#4129`:
1. Introduced split barrier guards (`RHICmdList.BeginTransitions(...)` / `EndTransitions(...)`) around Nanite compute dispatches.
2. Clamped per-frame camera ray projection deltas during camera cuts (`bIsCameraCutThisFrame = true`) to force immediate hierarchical frustum culling before cluster submission.

### Regression Verification Matrix
- **Test Build**: `Cooked-Shipping-CL89218`
- **Stress Test**: 200 rapid cutscene camera skips across `LV_AncientForest_P`.
- **Results**:
  - Crash count: 0 / 200 passes.
  - Max GPU frame time during streaming peak: 18.2ms (down from 2150ms hang).
  - VRAM consumption stabilized at 9.4GB (well within the 16GB RTX 4080 budget).

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build for simulator
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme VisionEmoji -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2'

# Build for device
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme VisionEmoji -destination generic/platform=iOS
```

No test target exists. No linter is configured. No SPM dependencies.

## Project Configuration

- **Target**: iOS 26.2, Xcode 17 (toolsVersion 2620), iPhone only
- **Swift**: Version 5.0 with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- **Orientation**: Portrait only on iPhone
- **Bundle ID**: `aristides.lintzeris.VisionEmoji`

Since `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, all types are implicitly `@MainActor`. Use `nonisolated` explicitly for code that must run off the main actor (e.g., Vision processing, camera frame callbacks).

## Architecture

Real-time camera → YOLO detection → per-object classification → emoji overlay pipeline:

```
CameraService (AVCaptureSession, ultrawide camera, frame delivery)
      ↓ CVPixelBuffer via onFrameProcessed callback
VisionService (YOLO26m detection + per-object crop classification on single DispatchQueue)
      ↓ [DetectionResult] via Combine @Published
EmojiOverlayService (position smoothing with Kalman filter, overlay management)
      ↓ [EmojiOverlay] via Combine @Published
SwiftUI overlay views (EmojiOverlayView)
```

**CameraService** manages AVCaptureSession on a dedicated `sessionQueue`. Uses `@Observable` (not `ObservableObject`). Defaults to ultrawide camera (`.builtInUltraWideCamera`). Discovers available cameras but does not expose switching/zoom. Delivers raw `CVPixelBuffer` frames via `onFrameProcessed` closure.

**VisionService** runs YOLO26m detection on a single `detectionQueue` (`.userInteractive` QoS). After detection, crops each detected object's bounding box and runs YOLO26m-cls for per-object ImageNet classification. Blends YOLO COCO labels with ImageNet labels based on a configurable priority slider. Publishes `[DetectionResult]`.

**EmojiOverlayService** transforms detection results into positioned overlays. Supports Kalman filtering or simple exponential smoothing for position stability. Configurable via `OverlaySettings`.

**EmojiAssetService** is a singleton that renders Apple emoji strings to `UIImage` via `NSAttributedString`. Uses `NSCache` for caching.

**ContentView** wires everything together: creates the services, connects camera frames → vision → overlays in `CameraTabView.setupServices()`. Includes a settings sheet and a "Reload" button that unloads/reloads models.

## YOLO CoreML Models

Two YOLO26 models (FP16), both end-to-end (`nms=False` forced by YOLO26):

| Model | File | Task | Input | Output |
|-------|------|------|-------|--------|
| YOLO26m | `yolo26m.mlpackage` | Detection | 640×640 | Raw tensor `[1, 300, 6]` |
| YOLO26m-cls | `yolo26m-cls.mlpackage` | Classification | 224×224 | `VNClassificationObservation` (ImageNet 1000) |

**Detection output**: `[1, 300, 6]` — each row is `[x1, y1, x2, y2, confidence, class_id]` in 640×640 pixel coords. **Y-flip required** for Vision coordinates: `y = 1.0 - (y2 / inputSize)`.

**Classification**: Per-object crop classification. Each detected bounding box is cropped from the frame via `CIImage.cropped(to:)`, resized to 224×224, and classified. Results cached per tracked object UUID for 2 seconds. Runs every 3rd frame, max 5 crops per frame.

**Label blending**: `labelPriority` slider controls YOLO vs ImageNet label:
- `< 0.3` → always use YOLO COCO label
- `> 0.7` → always use ImageNet label (if above cls confidence threshold)
- `0.3–0.7` → use ImageNet label when its confidence exceeds YOLO confidence

**Model loading**: Lazy-loaded via `getOrLoadModel()`, cached in `loadedModels` dict protected by `NSLock`. Xcode compiles `.mlpackage` to `.mlmodelc` at build time — load with `Bundle.main.url(forResource:withExtension:"mlmodelc")`.

**Emoji mapping**: `EmojiMapping` maps 80 COCO class indices → emojis. `imageNetToEmoji` maps ~100 common ImageNet labels → emojis. `imageNetToCOCOLabel` maps ImageNet labels back to COCO labels for fallback.

### Exporting Models with Ultralytics

```python
from ultralytics import YOLO

# Detection (FP16)
model = YOLO("yolo26m.pt")
model.export(format="coreml", half=True, imgsz=640, device="mps")

# Classification (FP16)
model = YOLO("yolo26m-cls.pt")
model.export(format="coreml", half=True, imgsz=224, device="mps")
```

YOLO26 forces `nms=False` regardless of the flag. Python 3.10 needed for coremltools (3.14 numpy incompatibility).

## Concurrency Patterns

VisionService is `@MainActor` (publishes to SwiftUI) but dispatches detection work to a single `detectionQueue` (`DispatchQueue`, `.userInteractive` QoS). Detection and classification run sequentially on this queue, then `resolveOverlapsAndPublish()` dispatches back to main.

- `nonisolated(unsafe)` on `trackedObjects`, `loadedModels`, `clsCache`, and other state accessed from the background queue
- `nonisolated private func` on detection/classification methods
- `NSLock` protects `trackedObjects`, `loadedModels`, and `clsCache` from concurrent access

## Detection and Overlap

Only one `DetectionType`: `.object` (green, priority 2). When bounding boxes overlap (IoU > 0.4 for different labels, IoU > 0.2 for same label), duplicates are suppressed. Max 20 tracked objects. Objects auto-expire after 1.5 seconds without updates.

## Key Gotchas

- **ML model build phase**: `.mlpackage` files must be in the **Sources** build phase (not Resources). Xcode compiles them to `.mlmodelc` bundles automatically.
- **CameraService uses `@Observable`** (not `ObservableObject`) — non-Sendable AVFoundation types require `nonisolated(unsafe)`.
- **Camera is locked to ultrawide** — no camera switching or zoom. Front cameras discovered but not selectable.
- **Reload button** calls `visionService.unloadAndReload()` + `emojiOverlayService.resetOverlays()` — clears models, cache, and tracked objects. Models auto-reload on next `processFrame()`.
- **Classification cache**: Per-object results cached for 2s in `clsCache` dict. Cleaned up periodically via `cleanupClassificationCache()`.
- **Settings UI**: Implemented as `SettingsOverlayView` in `ContentView.swift` (presented as a sheet). `SettingsView.swift` is kept for build compatibility only.

## Xcode Project File (project.pbxproj)

When adding new Swift files, you must add entries to all four sections:
1. **PBXBuildFile** — `<ID> /* File.swift in Sources */`
2. **PBXFileReference** — `<ID> /* File.swift */`
3. **PBXGroup** — add file ref to the appropriate group's `children`
4. **PBXSourcesBuildPhase** (`DF2C775D2F43335C00F1F0E7`) — add build file ref

Group IDs:
- Services: `DF2C77942F43335D00F1F0E7`
- Views: `DF2C77952F43335D00F1F0E7`
- Models: `DF2C77962F43335D00F1F0E7`

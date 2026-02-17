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

Real-time camera → Vision detection → emoji overlay pipeline:

```
CameraService (AVCaptureSession, frame delivery)
      ↓ CVPixelBuffer via onFrameProcessed callback
VisionService (face/hand/body/object detection on separate DispatchQueues)
      ↓ [DetectionResult] via Combine @Published
EmojiOverlayService (position smoothing with Kalman filter, overlay management)
      ↓ [EmojiOverlay] via Combine @Published
SwiftUI overlay views (AnimatedEmojiView, EmojiOverlayView)
```

**CameraService** manages AVCaptureSession on a dedicated `sessionQueue`. Delivers raw `CVPixelBuffer` frames via `onFrameProcessed` closure — does NOT dispatch to main thread first.

**VisionService** runs detection requests in parallel on separate DispatchQueues (`faceDetectionQueue`, `handDetectionQueue`, etc.). Publishes `[DetectionResult]` which includes bounding box, confidence, type, and emoji display info.

**EmojiOverlayService** transforms detection results into positioned overlays. Supports Kalman filtering or simple exponential smoothing for position stability. Configurable via `OverlaySettings`.

**EmojiAssetService** is a singleton that loads animated GIF frames from the `AnimatedEmojis/` folder reference (749 GIF files). Uses `NSCache` for caching. Falls back to static emoji strings when animated versions are unavailable.

**ContentView** wires everything together: creates the services, connects camera frames → vision → overlays via Combine pipelines in `CameraTabView.setupServices()`.

## YOLO CoreML Models

Three YOLO models, switchable at runtime via `VisionService.selectedModel`. All use 80 COCO classes mapped to emojis in `EmojiMapping`.

| Model | File | Size | Input | Architecture | Output |
|-------|------|------|-------|-------------|--------|
| YOLOv3 Tiny | `YOLOv3TinyFP16.mlmodel` | 17 MB | 416x416 | NMS pipeline | `VNRecognizedObjectObservation` |
| YOLO11 Nano | `yolo11n.mlpackage` | 5 MB | 640x640 | NMS pipeline (`nms=True`) | `VNRecognizedObjectObservation` |
| YOLO26 Nano | `yolo26n.mlpackage` | 5 MB | 640x640 | End-to-end (`nms=False`) | Raw tensor `[1, 300, 6]` |

**Model loading**: Lazy-loaded via `getOrLoadModel()`, cached in `loadedModels` dict protected by `NSLock`. Xcode compiles `.mlmodel`/`.mlpackage` to `.mlmodelc` at build time — load with `Bundle.main.url(forResource:withExtension:"mlmodelc")`.

**Two result-handling paths** in `VisionService`:
- **Pipeline models** (v3/11): Results arrive as `VNRecognizedObjectObservation` with normalized bounding boxes and string labels. Use `EmojiMapping.cocoLabelToEmoji[label]`.
- **End-to-end model** (26): Results arrive as `VNCoreMLFeatureValueObservation` containing an `MLMultiArray` with shape `[1, 300, 6]`. Each detection is `[x1, y1, x2, y2, confidence, class_id]` in pixel coords (640x640). **Y-flip required** for Vision coordinates: `y = 1.0 - (y2 / inputSize)`. Use `EmojiMapping.emoji(forClassIndex:)` for index-based lookup.

**"person" class is always skipped** in YOLO results — faces and bodies are handled by dedicated Vision APIs with higher detection priority.

### Adding a New YOLO Model

1. Add the `.mlmodel` or `.mlpackage` file to the Xcode project
2. Ensure it's in the **Sources** build phase (not Resources)
3. Add a case to the `YOLOModel` enum in `DetectionResult.swift` with `resourceName`, `isEndToEnd`, `inputSize`, and `subtitle`
4. If it's end-to-end, verify the tensor shape matches `[1, N, 6]` with field order `[x1, y1, x2, y2, conf, class_id]`

### Exporting Models with Ultralytics

```python
from ultralytics import YOLO
model = YOLO("yolo11n.pt")
model.export(format="coreml", nms=True)   # Pipeline → VNRecognizedObjectObservation

model = YOLO("yolo26n.pt")
model.export(format="coreml", nms=False)  # End-to-end → raw tensor [1, 300, 6]
```

YOLO26 forces `nms=False` regardless of the flag. Use `coremltools.proto.Model_pb2` to inspect model specs when `coremltools` native lib fails to load.

## Concurrency Patterns

VisionService is `@MainActor` (publishes to SwiftUI) but dispatches detection work to four parallel `DispatchQueue`s (`faceDetectionQueue`, `handDetectionQueue`, `bodyDetectionQueue`, `objectQueue`). A `DispatchGroup` synchronizes all queues, then `resolveOverlapsAndPublish()` runs on main.

- `nonisolated(unsafe)` on `trackedObjects`, `loadedModels`, and other state accessed from background queues
- `nonisolated private func` on detection methods (`performObjectDetection`, `handlePipelineResults`, etc.)
- `NSLock` protects `trackedObjects` and `loadedModels` dicts from concurrent queue access

## Detection Priority and Overlap

`DetectionType.priority`: face(4) > hand(3) > object(2) > body(1). When bounding boxes overlap (IoU > 0.4), the lower-priority detection is dropped. Max 20 tracked objects. Objects auto-expire after 1.5 seconds without updates.

## Key Gotchas

- **Animated GIFs**: Stored as a folder reference (`AnimatedEmojis/`) with ~749 `.gif` files named by Unicode codepoint (e.g., `1f600.gif`). Loaded via `Bundle.main.path(forResource:ofType:inDirectory:"AnimatedEmojis")`. `UIImage(data:)` only shows the first frame — use `CGImageSource` + `UIImageView.animationImages` for actual animation.
- **iOS 26 Liquid Glass**: `SettingsView` and `GlassEffectContainer` have dual code paths — `@available(iOS 26, *)` for glass effects and fallbacks for older versions. New UI using glass should follow this pattern.
- **Camera position**: `CameraService.switchCamera(to:position:)` toggles between front/back. VisionService is notified of camera position changes to optimize detection.
- **ML model build phase**: `.mlmodel` and `.mlpackage` files must be in the **Sources** build phase (not Resources). Xcode compiles them to `.mlmodelc` bundles automatically.
- **VNDetectRectanglesRequest** does NOT identify objects — it only finds geometric rectangles. Use YOLO CoreML models for object identification.

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

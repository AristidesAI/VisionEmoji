<p align="center">
  <img src="seenoevil Exports/seenoevil-iOS-Default-1024x1024@1x.png" width="180" alt="VisionEmoji App Icon" style="border-radius: 36px;" />
</p>

<h1 align="center">VisionEmoji</h1>

<p align="center">
  <strong>Real-time object detection → emoji overlay, 100% on-device</strong>
</p>

<p align="center">
  Point your camera at anything and watch matching Apple emojis appear instantly.<br/>
  Powered by <a href="https://docs.ultralytics.com/models/yolo26/">YOLO26</a> and <a href="https://developer.apple.com/documentation/coreml">CoreML</a> on the Apple Neural Engine.
</p>

<p align="center">
  <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-26.2-blue?logo=apple&logoColor=white" alt="iOS 26.2"></a>
  <a href="https://developer.apple.com/swift/"><img src="https://img.shields.io/badge/Swift-5-orange?logo=swift&logoColor=white" alt="Swift 5"></a>
  <a href="https://developer.apple.com/xcode/"><img src="https://img.shields.io/badge/Xcode-17-blue?logo=xcode&logoColor=white" alt="Xcode 17"></a>
  <a href="https://developer.apple.com/documentation/coreml"><img src="https://img.shields.io/badge/CoreML-FP16-green?logo=apple&logoColor=white" alt="CoreML"></a>
  <a href="https://developer.apple.com/machine-learning/"><img src="https://img.shields.io/badge/AI-On--Device-brightgreen" alt="On-Device AI"></a>
  <a href="PrivacyPolicy.md"><img src="https://img.shields.io/badge/Privacy-No%20Data%20Collected-brightgreen" alt="Privacy"></a>
</p>

---

## 📸 Screenshots

<p align="center">
  <img src="screenshots/IMG_6328.PNG" width="230" alt="Multi-object detection" />
  &nbsp;&nbsp;
  <img src="screenshots/IMG_6329.PNG" width="230" alt="Close-up emoji overlay" />
  &nbsp;&nbsp;
  <img src="screenshots/IMG_6338.PNG" width="230" alt="Settings and debug view" />
</p>

<p align="center">
  <em>Real-time desk analysis &nbsp;|&nbsp; Person detection &nbsp;|&nbsp; Debug mode with bounding boxes</em>
</p>

---

## ✨ Features

| | Feature | Description |
|---|---|---|
| 🎯 | **80+ Object Categories** | Detects people, animals, vehicles, food, electronics, and more (COCO dataset) |
| 🔬 | **1,000+ Classifications** | ImageNet classification per detected object for precise emoji matching |
| ⚡ | **Real-Time Performance** | Interactive frame rates on the Apple Neural Engine, Kalman-filtered for stability |
| 📷 | **Ultrawide Camera** | Maximum field of view to detect more objects simultaneously |
| 🔒 | **Privacy First** | 100% on-device — no internet, no data collection, no tracking, no ads |
| 🛠️ | **Debug Mode** | Toggle bounding boxes, classification labels, and confidence scores |
| 🎛️ | **Adjustable Settings** | Confidence threshold, emoji scale, label priority, smoothing mode |
| 🔄 | **Live Reload** | Unload and reload ML models on-the-fly without restarting |

---

## ⚙️ Architecture

```
📷 CameraService (AVCaptureSession, ultrawide camera)
      │ CVPixelBuffer
      ▼
🧠 VisionService (YOLO26m detection → per-object YOLO26m-cls classification)
      │ [DetectionResult]
      ▼
📐 EmojiOverlayService (Kalman filter smoothing, overlap resolution)
      │ [EmojiOverlay]
      ▼
😀 SwiftUI Overlay (EmojiOverlayView — positioned emoji renders)
```

All ML inference runs on a dedicated `DispatchQueue` at `.userInteractive` QoS. Results publish back to the main actor via Combine for SwiftUI rendering.

---

## 🧰 Tech Stack

| Technology | Role | Link |
|---|---|---|
| **Swift 5** | Primary language with strict concurrency | [swift.org](https://developer.apple.com/swift/) |
| **SwiftUI** | Declarative UI framework | [Apple Docs](https://developer.apple.com/xcode/swiftui/) |
| **CoreML** | On-device ML model inference | [Apple Docs](https://developer.apple.com/documentation/coreml) |
| **Vision** | Image analysis and request pipeline | [Apple Docs](https://developer.apple.com/documentation/vision) |
| **AVFoundation** | Camera capture and frame delivery | [Apple Docs](https://developer.apple.com/documentation/avfoundation) |
| **Combine** | Reactive data streaming | [Apple Docs](https://developer.apple.com/documentation/combine) |
| **YOLO26m** | Object detection (FP16, 640×640) | [Ultralytics Docs](https://docs.ultralytics.com/models/yolo26/) |
| **YOLO26m-cls** | Image classification (FP16, 224×224) | [Ultralytics Classify](https://docs.ultralytics.com/tasks/classify/) |
| **coremltools** | Model conversion to CoreML format | [coremltools](https://coremltools.readme.io/) |
| **Xcode 17** | IDE + toolchain (toolsVersion 2620) | [Apple Developer](https://developer.apple.com/xcode/) |

---

## 🧠 ML Models

Two YOLO26 CoreML models (FP16), both end-to-end:

| Model | Task | Input | Output |
|---|---|---|---|
| `yolo26m.mlpackage` | Detection | 640×640 | `[1, 300, 6]` — `[x1, y1, x2, y2, conf, class_id]` |
| `yolo26m-cls.mlpackage` | Classification | 224×224 | `VNClassificationObservation` (ImageNet 1000) |

### Exporting Models

```python
from ultralytics import YOLO

# Detection (FP16)
model = YOLO("yolo26m.pt")
model.export(format="coreml", half=True, imgsz=640, device="mps")

# Classification (FP16)
model = YOLO("yolo26m-cls.pt")
model.export(format="coreml", half=True, imgsz=224, device="mps")
```

> Python 3.10 required (coremltools numpy compatibility). YOLO26 forces `nms=False` regardless of flag.

---

## 🏗️ Build

```bash
# Simulator
xcodebuild -scheme VisionEmoji \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2'

# Physical device
xcodebuild -scheme VisionEmoji \
  -destination generic/platform=iOS
```

**Requirements:**
- Xcode 17+ (toolsVersion 2620)
- iOS 26.2+ target
- Physical device recommended (camera required for full functionality)
- No SPM dependencies — zero external packages

---

## 🔒 Privacy

VisionEmoji **does not collect any data**. All processing runs entirely on-device.

| | Guarantee |
|---|---|
| ✅ | Camera frames processed on-device only |
| ✅ | No images stored, transmitted, or logged |
| ✅ | No internet connection required |
| ✅ | No third-party analytics or tracking |
| ✅ | No accounts, no ads |

See the full [Privacy Policy](PrivacyPolicy.md).

---

## 📂 Project Structure

```
VisionEmoji/
├── VisionEmojiApp.swift          # App entry point
├── ContentView.swift             # Main view + service wiring
├── Services/
│   ├── CameraService.swift       # AVCaptureSession management
│   ├── VisionService.swift       # YOLO detection + classification
│   ├── EmojiOverlayService.swift # Position smoothing + overlay management
│   └── EmojiAssetService.swift   # Emoji → UIImage rendering + cache
├── Models/
│   └── DetectionResult.swift     # Detection data model
├── Views/
│   ├── CameraView.swift          # Camera preview (UIViewRepresentable)
│   ├── EmojiOverlayView.swift    # Emoji overlay rendering
│   ├── AnimatedEmojiView.swift   # Animated emoji display
│   ├── SettingsView.swift        # Settings sheet
│   ├── PermissionRequestView.swift
│   └── GlassEffectContainer.swift
├── yolo26m.mlpackage             # YOLO26m detection model
└── yolo26m-cls.mlpackage         # YOLO26m-cls classification model
```

---

## 🌐 Website

A project website is included in [`docs/`](docs/index.html). To preview locally:

```bash
cd docs && python3 -m http.server 8000
```

Then open [http://localhost:8000](http://localhost:8000).

---

## 📄 License

MIT © 2026 [Aristides Lintzeris](mailto:aristideslintzeris@icloud.com)

---

<p align="center">
  Built with 🧠 CoreML + ❤️ SwiftUI
  <br/><br/>
  🙈 🐶 🚗 🍕 📱 🐱 ✈️ 🌻 🎸 🏀
</p>

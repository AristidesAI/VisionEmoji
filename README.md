<p align="center">
  <img src="VisionEmoji/Assets.xcassets/AppIcon.appiconset/Icon-iOS-Default-1024x1024@1x.png" width="128" height="128" alt="VisionEmoji App Icon" style="border-radius: 22px;">
</p>

<h1 align="center">VisionEmoji</h1>

<p align="center">
  <strong>Real-time AI-powered emoji overlay for iOS</strong><br>
  Point your camera at the world and watch objects transform into emojis instantly.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-26.2-blue?logo=apple&logoColor=white" alt="iOS 26.2">
  <img src="https://img.shields.io/badge/Swift-5-orange?logo=swift&logoColor=white" alt="Swift 5">
  <img src="https://img.shields.io/badge/Xcode-17-blue?logo=xcode&logoColor=white" alt="Xcode 17">
  <img src="https://img.shields.io/badge/CoreML-FP16-green?logo=apple&logoColor=white" alt="CoreML">
  <img src="https://img.shields.io/badge/YOLO26-Detection+Classification-purple?logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48Y2lyY2xlIGN4PSIxMiIgY3k9IjEyIiByPSIxMCIgZmlsbD0id2hpdGUiLz48L3N2Zz4=" alt="YOLO26">
</p>

---

## Screenshots

<p align="center">
  <img src="screenshots/IMG_6338.PNG" width="230" alt="Debug mode with bounding boxes">&nbsp;&nbsp;
  <img src="screenshots/IMG_6328.PNG" width="230" alt="Object detection on desk">&nbsp;&nbsp;
  <img src="screenshots/IMG_6329.PNG" width="230" alt="Person detection">
</p>

<p align="center">
  <em>Debug mode with bounding boxes &nbsp;|&nbsp; Real-time desk analysis &nbsp;|&nbsp; Person detection</em>
</p>

---

## Features

- **Real-Time Object Detection** — YOLO26m processes camera frames at up to 60 FPS on Apple Neural Engine
- **Dual-Model Pipeline** — Detection (80 COCO classes) + per-object crop classification (1000 ImageNet classes)
- **Native Apple Emojis** — Beautiful built-in emojis rendered via `NSAttributedString` with `NSCache` optimization
- **Kalman Filter Smoothing** — Configurable process & measurement noise for rock-stable overlay positions
- **100% On-Device** — All inference runs locally via CoreML. No data leaves your iPhone
- **Configurable** — FPS cap, emoji scale, confidence thresholds, label priority, and Kalman parameters
- **Ultrawide Camera** — Default to ultra-wide lens for maximum field of view
- **De-duplication** — IoU-based overlap resolution prevents duplicate emoji overlays

---

## Technologies Used

| Technology | Description | Link |
|:---|:---|:---|
| **Swift** | Primary programming language | [swift.org](https://swift.org) |
| **SwiftUI** | Declarative UI framework | [Apple SwiftUI](https://developer.apple.com/xcode/swiftui/) |
| **CoreML** | On-device machine learning inference | [Apple CoreML](https://developer.apple.com/machine-learning/core-ml/) |
| **Vision** | Image analysis and object detection framework | [Apple Vision](https://developer.apple.com/documentation/vision) |
| **AVFoundation** | Camera capture and media processing | [Apple AVFoundation](https://developer.apple.com/av-foundation/) |
| **Combine** | Reactive data flow between services | [Apple Combine](https://developer.apple.com/documentation/combine) |
| **YOLO26** | State-of-the-art real-time object detection | [Ultralytics](https://docs.ultralytics.com/) |
| **coremltools** | Model conversion to CoreML format | [coremltools](https://coremltools.readme.io/) |

---

## Architecture

```
CameraService (AVCaptureSession, ultrawide camera, frame delivery)
      | CVPixelBuffer via onFrameProcessed callback
      v
VisionService (YOLO26m detection + per-object crop classification)
      |  ┌──────────────────┐    ┌─────────────────────────────┐
      |  │ YOLO26m Detect   │ -> │ Per-Object Crop Classify     │
      |  │ 640x640 [1,300,6]│    │ 224x224 ImageNet 1000        │
      |  └──────────────────┘    └─────────────────────────────┘
      |              Label Blending (priority slider)
      v
EmojiOverlayService (Kalman filter smoothing, overlay management)
      | [EmojiOverlay] via @Published
      v
SwiftUI Overlay Views (EmojiOverlayView -> ContentView)
```

---

## ML Models

| Model | Task | Input | Output | Format |
|:---|:---|:---|:---|:---|
| `yolo26m` | Detection | 640x640 | `[1, 300, 6]` — `[x1, y1, x2, y2, conf, class]` | FP16 CoreML |
| `yolo26m-cls` | Classification | 224x224 | `VNClassificationObservation` (1000 classes) | FP16 CoreML |

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

> Requires Python 3.10 and `coremltools`. YOLO26 forces `nms=False` regardless of the flag.

---

## Build

```bash
# Simulator
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -scheme VisionEmoji \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2'

# Device
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -scheme VisionEmoji \
  -destination generic/platform=iOS
```

---

## Project Structure

```
VisionEmoji/
├── VisionEmoji/
│   ├── VisionEmojiApp.swift        # App entry point
│   ├── ContentView.swift           # Main view + settings sheet
│   ├── Services/
│   │   ├── CameraService.swift     # AVCaptureSession management
│   │   ├── VisionService.swift     # YOLO detection + classification
│   │   ├── EmojiOverlayService.swift # Overlay positioning + Kalman
│   │   └── EmojiAssetService.swift # Emoji string → UIImage cache
│   ├── Models/
│   │   ├── DetectionResult.swift   # Detection data model
│   │   ├── EmojiMapping.swift      # COCO + ImageNet → emoji maps
│   │   └── EmojiOverlay.swift      # Overlay position model
│   └── Views/
│       ├── CameraTabView.swift     # Camera feed + overlay layer
│       ├── EmojiOverlayView.swift  # SwiftUI emoji rendering
│       └── SettingsView.swift      # Settings UI
├── yolo26m.mlpackage               # Detection model
├── yolo26m-cls.mlpackage           # Classification model
├── screenshots/                    # App screenshots
└── index.html + style.css          # Project website
```

---

## Credits

Made by **Aristides Lintzeris** & **YOLO26**

---

<p align="center">
  🙈 🐶 🚗 🍕 📱 🐱 ✈️ 🌻 🎸 🏀
</p>

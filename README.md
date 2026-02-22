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

<p align="center">
  <a href="https://apps.apple.com/us/app/vision-emoji/id6759308509">
    <img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83" alt="Download on the App Store" height="60" />
  </a>
</p>

---

## Screenshots

<p align="center">
  <img src="screenshots/IMG_6377.PNG" width="180" alt="Dog detection with emoji overlay" />
  &nbsp;
  <img src="screenshots/IMG_6341.PNG" width="180" alt="Living room scene detection" />
  &nbsp;
  <img src="screenshots/IMG_6342.PNG" width="180" alt="Kitchen objects detection" />
  &nbsp;
  <img src="screenshots/IMG_6335.PNG" width="180" alt="Workspace with 9 objects tracked" />
  &nbsp;
  <img src="screenshots/IMG_6338.PNG" width="180" alt="Debug mode with bounding boxes" />
</p>

<p align="center">
  <em>Pet detection &nbsp;|&nbsp; Room scan &nbsp;|&nbsp; Kitchen &nbsp;|&nbsp; Workspace &nbsp;|&nbsp; Debug mode</em>
</p>

---

## Features

| Feature | Description |
|---|---|
| **80+ Object Categories** | Detects people, animals, vehicles, food, electronics, and more (COCO dataset) |
| **1,000+ Classifications** | ImageNet classification per detected object for precise emoji matching |
| **Real-Time Performance** | Interactive frame rates on the Apple Neural Engine, Kalman-filtered for stability |
| **Ultrawide Camera** | Maximum field of view to detect more objects simultaneously |
| **Privacy First** | 100% on-device — no internet, no data collection, no tracking, no ads |
| **Debug Mode** | Toggle bounding boxes, classification labels, and confidence scores |
| **Adjustable Settings** | Confidence threshold, emoji scale, label priority, smoothing mode |
| **Live Reload** | Unload and reload ML models on-the-fly without restarting |

---

## Architecture

```
CameraService (AVCaptureSession, ultrawide camera)
      | CVPixelBuffer
      v
VisionService (YOLO26m detection → per-object YOLO26m-cls classification)
      | [DetectionResult]
      v
EmojiOverlayService (Kalman filter smoothing, overlap resolution)
      | [EmojiOverlay]
      v
SwiftUI Overlay (EmojiOverlayView — positioned emoji renders)
```

All ML inference runs on a dedicated `DispatchQueue` at `.userInteractive` QoS. Results publish back to the main actor via Combine for SwiftUI rendering.

---

## Privacy

VisionEmoji **does not collect any data**. All processing runs entirely on-device.

See the full [Privacy Policy](PrivacyPolicy.md).

---

## License

MIT © 2026 [Aristides Lintzeris](mailto:aristideslintzeris@icloud.com)

---

<p align="center">
  Built with CoreML + SwiftUI
</p>

<p align="center">
  <img src="3d-emojis/see-no-evil-monkey.png" width="36" alt="see no evil" />
  &nbsp;
  <img src="3d-emojis/dog-face.png" width="36" alt="dog" />
  &nbsp;
  <img src="3d-emojis/automobile.png" width="36" alt="car" />
  &nbsp;
  <img src="3d-emojis/pizza.png" width="36" alt="pizza" />
  &nbsp;
  <img src="3d-emojis/mobile-phone.png" width="36" alt="phone" />
  &nbsp;
  <img src="3d-emojis/cat-face.png" width="36" alt="cat" />
  &nbsp;
  <img src="3d-emojis/airplane.png" width="36" alt="airplane" />
  &nbsp;
  <img src="3d-emojis/sunflower.png" width="36" alt="sunflower" />
  &nbsp;
  <img src="3d-emojis/guitar.png" width="36" alt="guitar" />
  &nbsp;
  <img src="3d-emojis/basketball.png" width="36" alt="basketball" />
</p>

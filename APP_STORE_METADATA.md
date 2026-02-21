# VisionEmoji — App Store Connect Metadata

## App Information

| Field | Value |
|-------|-------|
| **App Name** | VisionEmoji |
| **Subtitle** | Real-Time Emoji Object Detection |
| **Bundle ID** | aristides.lintzeris.VisionEmoji |
| **SKU** | VisionEmoji2026 |
| **Primary Language** | English (U.S.) |
| **Category** | Entertainment |
| **Secondary Category** | Photo & Video |
| **Content Rights** | Does not contain third-party content |
| **Age Rating** | 4+ |
| **Price** | Free |
| **Copyright** | 2026 Aristides Lintzeris |

---

## Version Information

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Build** | 1 |
| **What's New** | Initial release |

---

## Description

VisionEmoji uses advanced on-device machine learning to detect real-world objects through your camera and instantly overlays matching Apple emojis on top of them — all in real time.

Powered by YOLO26, a state-of-the-art object detection model running entirely on your device's Apple Neural Engine, VisionEmoji recognizes over 80 object categories including people, animals, vehicles, food, electronics, and more. A secondary classification model identifies over 1,000 specific object types for even more accurate emoji matching.

**Key Features:**

- Real-time object detection with instant emoji overlay
- 80+ COCO object categories with matching emojis
- 1,000+ ImageNet class recognition for detailed identification
- Runs 100% on-device — no internet connection required, no data leaves your phone
- Adjustable detection confidence, emoji scale, and display settings
- Debug mode to see bounding boxes and classification labels
- Kalman filter smoothing for stable, jitter-free emoji tracking
- Ultrawide camera support for maximum field of view

**How It Works:**

Point your camera at any object. VisionEmoji instantly detects what it sees and places the matching emoji right on top of it. A dog becomes 🐕, a car becomes 🚗, a cup of coffee becomes ☕, and much more. The emojis follow objects in real time as they move through the frame.

**Privacy First:**

All processing happens entirely on your iPhone using the Apple Neural Engine. No images, video, or detection data ever leave your device. No account required. No tracking. No ads.

**Best experienced on iPhone 16 or later** for optimal Neural Engine performance. Compatible with all iPhones running iOS 26.

---

## Promotional Text

Point your camera at anything and watch emojis appear in real time — powered by on-device AI.

---

## Keywords

emoji,object detection,camera,AI,machine learning,YOLO,real-time,augmented reality,neural engine,CoreML,emoji overlay,computer vision,fun camera,object recognition,live emoji

---

## Support URL

https://github.com/aristideslintzeris/VisionEmoji

---

## Privacy Policy URL

https://github.com/aristideslintzeris/VisionEmoji/blob/main/PRIVACY.md

---

## App Privacy Details

### Data Collection

**VisionEmoji does not collect any data.** Select "Data Not Collected" for all categories in App Store Connect.

| Data Type | Collected? | Notes |
|-----------|-----------|-------|
| Contact Info | No | — |
| Health & Fitness | No | — |
| Financial Info | No | — |
| Location | No | — |
| Sensitive Info | No | — |
| Contacts | No | — |
| User Content | No | — |
| Browsing History | No | — |
| Search History | No | — |
| Identifiers | No | — |
| Usage Data | No | — |
| Diagnostics | No | — |
| Photos or Videos | No | Camera feed processed on-device only, never stored or transmitted |

---

## App Review Notes

VisionEmoji requires camera access to function. The app uses the camera to detect real-world objects and overlay matching emojis in real time. All machine learning inference runs on-device using CoreML and the Apple Neural Engine. No data is collected, stored, or transmitted.

To test: Grant camera access when prompted, then point the camera at common objects (people, cups, phones, chairs, etc.) to see emojis appear. Tap the Settings tab to adjust detection settings and switch between Emoji and Debug display modes.

The app requires a physical device with a camera for full functionality. It will not function in the iOS Simulator.

---

## Screenshots Needed

Capture these on **iPhone 16 Pro Max** (6.9") and **iPhone SE** (4.7") at minimum:

1. **Hero shot** — Camera pointing at a scene with multiple emojis overlaid on objects
2. **Close-up** — Single object with large emoji overlay (e.g., a dog with 🐕)
3. **Settings** — Settings sheet showing detection and display options
4. **Debug mode** — Bounding boxes visible with classification labels
5. **Multiple objects** — Busy scene with 5+ objects detected simultaneously

### Screenshot Sizes Required

| Device | Size (pixels) |
|--------|---------------|
| iPhone 16 Pro Max (6.9") | 1320 x 2868 |
| iPhone 16 Pro (6.3") | 1206 x 2622 |
| iPhone SE (4.7") | 750 x 1334 |

---

## Export Compliance

| Question | Answer |
|----------|--------|
| Uses encryption? | No |
| Contains proprietary encryption? | No |
| Uses standard encryption (HTTPS, etc.)? | No (fully offline app) |

`ITSAppUsesNonExemptEncryption` is set to `NO` in Info.plist to skip the manual declaration on each build upload.

---

## Checklist Before Submission

- [ ] App icon displays correctly (light, dark, tinted variants)
- [ ] Launch screen shows black background (matches loading overlay)
- [ ] Camera permission prompt appears on first launch
- [ ] Objects are detected and emojis overlay correctly
- [ ] Settings sheet opens and all controls work without FPS drops
- [ ] Debug mode shows bounding boxes and classification labels
- [ ] Reload button clears and reloads models
- [ ] App works without internet connection
- [ ] Screenshots captured on required device sizes
- [ ] Privacy policy URL is live and accessible
- [ ] Support URL is live and accessible
- [ ] Bundle ID matches App Store Connect registration
- [ ] Version and build numbers are correct
- [ ] Archive builds successfully for distribution
- [ ] Tested on physical device (iPhone 16 or later recommended)

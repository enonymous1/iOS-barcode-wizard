# Changelog

## 2.0.0 — 2026-10-26

Public export note: this repository is a squashed export of the v2.0.0 modernization. It contains a single commit under the enonymous1 identity; the original project's earlier history is not included. The Xcode project, target, and scheme intentionally stay named BW — only the repository folder was renamed to barcode-wizard.

Full modernization of the May–June 2023 UIKit barcode scanner (v1.0). The app does the same job — scan a barcode, see the product, keep it — but the scan-to-detail flow now actually works end to end, and items are really saved.

### Fixed

- **Scan flow dead-ended**: v1's scan segue landed on a `searchVC` scene with no custom class, so the scanned item was dropped and the user got an empty table. Scanning now navigates to the item's detail screen.
- **Nothing was ever saved**: v1 contained no Firestore write call anywhere, so its saved-items list could only ever show what its read happened to have fetched. Saving an item (from a scan or from the detail screen) now writes to Firestore, and the list reloads from the store.
- **Items keyed by email address**: v1 read from a Firestore collection named after the user's email, with force-unwraps on the snapshot and every document. Items now live at `users/{uid}/items/{barcode}`, keyed by the Firebase Auth UID and the barcode.
- **One scan, many lookups**: the camera delegate fired once per video frame, and v1 called its lookup (and its segue) on every frame. A `ScanDeduplicator` now lets one physical scan produce one lookup, and the capture session stops when the scan tab disappears.
- **Blank items presented as successes**: v1's live lookups force-unwrapped the URL and barcode, ignored HTTP status, and presented a blank item when decoding failed. Lookups now check the HTTP status, and a 404/decoding failure produces an editable placeholder with a "not found, enter it yourself" message; a network failure produces an error message and no item.
- **A lookup that corrupted barcodes**: v1's dead `findWithBarcodeMonster` dropped the first character of every barcode (`dropFirst()`). Barcodes are now used exactly as scanned, apart from surrounding whitespace, and that function is gone.
- **Second, broken camera path**: `CameraVC`/`CameraSetup` were unwired, and their setup loop never set the rear camera before force-unwrapping it. Both files are deleted; `ScannerCameraView` is the only camera code, with a permission check, a denied-permission state, and a Settings button.
- **Sign-out that could not reset the screen**: v1 swapped the root controller through the deprecated `keyWindow`, which is unreliable under SceneDelegate. Sign-out is now a view-model action that clears auth state, and the root view switches on that state.
- **Dead AppDelegate auto-login**: the AppDelegate branch set a root controller on a window SceneDelegate owns. Auth state is now a single conditional in `ContentView`.
- **Empty screens with no explanation**: `HelpVC` was three "FAQ #n" rows with no content, `ItemVC`'s edit button only printed, and `ViewController.swift` was an empty template with no scene. Help is real content, edit saves, and the empty controller is deleted.
- **Empty Core Data model with a crashing template stack**: the model had no entities, yet AppDelegate carried the template `persistentContainer` with `fatalError` on failure. Core Data is removed entirely; persistence is Firestore.
- **Force-unwrap crashes throughout**: `ItemVC` unwrapped the image URL and labels, `HomeVC` unwrapped the query snapshot and decoded documents, `ScannerVC` unwrapped the capture input with `try!`. The v2 code has no force unwraps in app code outside the one compile-time-constant lookup base URL.

### Changed

- Rewrote in SwiftUI with `@Observable` view models: `BWApp`, auth form, tabbed main view (Items / Scan / Help), item list and detail, and the scanner. AppDelegate, SceneDelegate, both storyboards, the generated Info.plist, and the empty Core Data model are gone; Info.plist keys (including the camera usage description and display name) are generated from build settings.
- Auth and data access are protocols (`AuthService`, `ItemStore`, `ProductLookupService`) with Firebase implementations and in-memory fakes, so view models are testable without Firebase or the network.
- Auth uses Firebase's async/await API instead of completion handlers, validation is a pure function returning a message (not an alert side effect), passwords must be at least 8 characters, and there is a forgot-password flow, which v1 lacked.
- The detail screen uses `AsyncImage` with a placeholder and a failure state instead of a raw data task, a spinner that never stopped on error, and an unused image-view outlet.
- The list shows description (or barcode), company, and size, is searchable, supports swipe-to-delete and pull-to-refresh, and loads with loading/empty/error states instead of passing whatever had arrived by segue time.
- Toolchain: Swift 6 language mode, iOS 17.0 deployment target (required by `@Observable` and `ContentUnavailableView`), Xcode 27.1, Firebase iOS SDK 12.x via Swift Package Manager (Auth, Firestore, FirestoreSwift, Core only — the unused Analytics and Database products v1 linked are dropped).
- Bundle identifier changed from the original author-named identifier to `com.enonymous1.barcodewizard`, and the hardcoded Apple development team ID was removed, so the project builds for the simulator without personal signing configuration. This also means a new Firebase project configuration for the new bundle ID — see the README.
- App icon slots are now filled with a generated barcode icon (17 slots, pixel-verified), the accent color is a real blue, and the dead 284K `AppIcons` asset folder is gone.
- Tracked `xcuserdata` is removed, and `.gitignore` now covers it, `GoogleService-Info.plist`, and build products.

### Added

- 18 Swift Testing tests: product decoding (legacy keys, missing-field defaults, malformed JSON), validation (email, password length, barcode normalization), scan deduplication (repeat suppression, different code, window expiry), and view models (found barcode, duplicate scan, not-found placeholder, network failure, list load/search/save/delete, auth form validation).
- A `BWTests` unit-test target, GitHub Actions CI (SwiftLint plus a simulator build and test run on iPhone 17), a SwiftLint configuration, a privacy manifest, MIT LICENSE, this changelog, and a `.gitattributes` file normalizing line endings to LF.

### Notes and non-goals

- The Barcode Monster provider is kept from v1, but its reliability is unverified in 2026 — it was already flaky in 2023. If it fails in practice, replace `BarcodeMonsterService` with another `ProductLookupService`; the scanner does not depend on the provider.
- The project was not built locally for this modernization: there is no Xcode or Swift toolchain on the Linux machine that produced it. The build gate is the GitHub Actions CI run and Xcode on a Mac after pushing — the project file was validated for balanced structure, no dangling file references, all 17 icon slots pixel-correct, and no leftover storyboard, team-ID, or old-version settings, but that is not a substitute for a real `xcodebuild` run.
- Scanning needs a physical device with a camera; the Simulator shows the camera-unavailable state by design.

## 1.0.0 — 2023

Original Full Sail project: UIKit + storyboards, Firebase Authentication and Firestore, AVFoundation barcode scanning, Barcode Monster product lookup. Registration, sign-in, and scanning were working in June 2023, with the scan-to-detail and persistence gaps listed above still open.

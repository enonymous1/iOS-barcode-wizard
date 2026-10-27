# Barcode Wizard

Scan a product barcode with your iPhone camera, look up the product, and keep it in your own saved-items list. Sign in once, and your items follow your account.

## What it does

- **Sign in or register** with email and password (Firebase Authentication), including a forgot-password flow.
- **Scan barcodes** with the camera: EAN-8, EAN-13, UPC-E, Code 39, Code 93, and Code 128.
- **Look up products** through the Barcode Monster API, with a clear result when a barcode isn't in the database.
- **Save items** to Firestore under your account, edit them, search them, and delete them with a swipe.
- **Enter items by hand** when a lookup finds nothing: the detail screen opens in edit mode so you can fill in company, description, and size yourself.

## Tech stack

- Swift 6 language mode, SwiftUI, iOS 17.0 or newer, Xcode 27.1
- AVFoundation for camera capture and barcode detection
- Firebase Authentication and Cloud Firestore via Swift Package Manager (Firebase iOS SDK 12.x)
- Swift Testing for unit tests, SwiftLint, GitHub Actions CI

## Setup

1. Clone the repository and open the project:

   ```bash
   git clone https://github.com/enonymous1/barcode-wizard.git
   cd barcode-wizard
   open BW.xcodeproj
   ```

2. In the Firebase Console, create or select a project, enable Email/Password Authentication, and enable Firestore.

3. Download that project's `GoogleService-Info.plist` and add it to the **BW** target in Xcode. This file is intentionally gitignored — never commit it.

   Without it, the app opens to a setup screen instead of crashing, but sign-in and saving won't work until it's added.

4. Select the `BW` scheme, choose a development team under **Signing & Capabilities**, and run on a physical device. The camera-based workflow cannot be tested in the Simulator, which has no camera.

## Usage

1. Register or sign in.
2. Open the Scan tab and point the camera at a barcode.
3. If the product is found, its details appear. If not, enter them yourself and save.
4. Browse, search, and edit your items on the Items tab.

## Data layout

Items live in Firestore at `users/{uid}/items/{barcode}`, where `{uid}` is the Firebase Auth user ID and `{barcode}` is the scanned code. Saving the same barcode twice updates the item instead of duplicating it.

### Migrating from v1

v1 never actually wrote items to Firestore, and its read path used a collection named after the user's email address. v2 does not migrate those email-named collections automatically: if you have data under one, move it to `users/{uid}/items/` (document ID = barcode) before relying on the v2 list.

## Privacy

- The app collects your email address (for sign-in) and the items you save. Both are stored in your own Firebase project, under your account.
- The camera feed is processed on-device for barcode detection; video is never uploaded.
- Product lookups send the scanned barcode to Barcode Monster over HTTPS.
- See `BW/PrivacyInfo.xcprivacy` for the app's privacy manifest.

## Limitations

- Product lookup depends on Barcode Monster's availability and coverage. It was already returning intermittent errors during v1 development in 2023; if it becomes unreliable, the lookup service is a single protocol (`ProductLookupService`) behind the scanner, so swapping providers is one new type.
- Barcode lookup and Firestore require a network connection. Saved items are not yet cached offline in the app itself (Firestore's own offline persistence still applies to its reads).
- There is no account deletion flow yet; delete the user from the Firebase Console to remove an account and its items.

## License

MIT — see [LICENSE](LICENSE).

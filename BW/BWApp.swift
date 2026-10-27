import FirebaseCore
import SwiftUI

/// SwiftUI app entry point. v1's AppDelegate, SceneDelegate, both
/// storyboards, and the generated Info.plist are gone: the scene is
/// the WindowGroup below, and Info.plist keys are generated from
/// the target's build settings.
///
/// Firebase is configured only when a GoogleService-Info.plist is
/// present in the bundle. Without it the app shows a setup screen
/// instead of crashing in FirebaseApp.configure(), which is also
/// what makes a plain simulator build (and CI's test host) safe
/// before the developer has added their own Firebase project.
@main
struct BWApp: App {
    init() {
        if Bundle.main.url(
            forResource: "GoogleService-Info",
            withExtension: "plist"
        ) != nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

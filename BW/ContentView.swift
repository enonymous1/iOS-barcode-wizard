import FirebaseCore
import SwiftUI

/// Root view. Three states, in order:
///
/// 1. No Firebase configuration: a setup screen, not a crash.
///    This is the state a fresh checkout is in until the developer
///    adds their own GoogleService-Info.plist.
/// 2. No signed-in user: the auth screen.
/// 3. Signed in: the main tabs — items, scanner, help.
///
/// v1 split this across AppDelegate (a dead root-controller swap
/// on a window SceneDelegate owns) and StartVC (a segue in
/// viewDidAppear). Here it is one conditional on auth state.
struct ContentView: View {
    @State private var authViewModel = AuthViewModel(
        service: FirebaseAuthService()
    )

    var body: some View {
        if FirebaseApp.app() == nil {
            SetupNeededView()
        } else if let user = authViewModel.user {
            MainTabView(user: user, authViewModel: authViewModel)
        } else {
            AuthView(viewModel: authViewModel)
        }
    }
}

/// The tab bar. Each tab owns its own NavigationStack so the
/// scanner and the list keep independent navigation state, and
/// the list's view model is shared with the detail screens so a
/// save from the scanner or the detail screen lands in the list.
struct MainTabView: View {
    let user: AuthUser
    let authViewModel: AuthViewModel

    @State private var listViewModel: ItemListViewModel?

    var body: some View {
        TabView {
            if let listViewModel {
                ItemListView(viewModel: listViewModel)
                    .tabItem {
                        Label("Items", systemImage: "list.bullet")
                    }
                ScannerView(
                    listViewModel: listViewModel,
                    userID: user.uid
                )
                .tabItem {
                    Label("Scan", systemImage: "barcode.viewfinder")
                }
            } else {
                ProgressView("Loading items")
                    .tabItem {
                        Label("Items", systemImage: "list.bullet")
                    }
            }
            HelpView()
                .tabItem {
                    Label("Help", systemImage: "questionmark.circle")
                }
        }
        .task {
            if listViewModel == nil {
                let model = ItemListViewModel(
                    store: FirebaseItemStore(),
                    userID: user.uid
                )
                listViewModel = model
                await model.load()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Sign Out") {
                    authViewModel.signOut()
                }
            }
        }
    }
}

/// Shown when no GoogleService-Info.plist is in the bundle. This
/// replaces v1's crash-on-launch without a Firebase project, and
/// tells the developer exactly what to do about it.
struct SetupNeededView: View {
    var body: some View {
        ContentUnavailableView {
            Label(
                "Firebase setup needed",
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text(
                "Add your GoogleService-Info.plist to the BW target, "
                    + "then rebuild. See the README's Setup section."
            )
        }
    }
}

import SwiftUI

/// Help, as real content. v1's Help tab was three rows reading
/// "FAQ #1" through "FAQ #3" with no answers and no tap action.
struct HelpView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Scanning") {
                    Text(
                        "Point the camera at a barcode. Supported "
                            + "types are EAN-8, EAN-13, UPC-E, Code 39, "
                            + "Code 93, and Code 128."
                    )
                    Text(
                        "Scanning needs a physical device with a "
                            + "camera. The Simulator has no camera, "
                            + "so the preview stays blank there."
                    )
                }
                Section("When a barcode is not found") {
                    Text(
                        "The product database does not cover every "
                            + "barcode. When nothing is found, the "
                            + "app opens the item in edit mode so "
                            + "you can enter the company, description, "
                            + "and size yourself, then save it."
                    )
                }
                Section("Your items") {
                    Text(
                        "Saved items are stored in Firestore under "
                            + "your account, keyed by barcode, so "
                            + "saving the same item twice updates it "
                            + "instead of duplicating it."
                    )
                    Text(
                        "Swipe left on an item in the list to "
                            + "delete it."
                    )
                }
                Section("Account") {
                    Text(
                        "Sign out from the button at the top of "
                            + "the screen. Forgotten passwords can "
                            + "be reset from the sign-in form."
                    )
                }
            }
            .navigationTitle("Help")
        }
    }
}

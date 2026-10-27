import SwiftUI

/// The scan tab. The camera preview fills the top of the screen;
/// a detected code runs through `ScannerViewModel`, and a resolved
/// item navigates to its detail screen, where it can be edited
/// and saved. v1's scan segue landed on an uncustomized table
/// controller that dropped the scanned item entirely.
///
/// Scanning states, each with its own UI instead of a silent
/// black viewfinder:
/// - Camera denied: an explanation and a button to Settings.
/// - Looking up: a spinner over the preview.
/// - Lookup message: an inline banner (for example, "not found,
///   enter it yourself") above the preview.
struct ScannerView: View {
    let listViewModel: ItemListViewModel
    let userID: String

    @State private var viewModel = ScannerViewModel(
        lookup: BarcodeMonsterService()
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.cameraDenied {
                    ContentUnavailableView {
                        Label(
                            "Camera access needed",
                            systemImage: "camera.slash"
                        )
                    } description: {
                        Text(
                            "Barcode Wizard needs camera access "
                                + "to scan barcodes."
                        )
                    } actions: {
                        Button("Open Settings") {
                            if let url = URL(
                                string: UIApplication.openSettingsURLString
                            ) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ZStack {
                        ScannerCameraView(
                            onCode: { code in
                                Task { await viewModel.didScan(code) }
                            },
                            onPermissionDenied: {
                                viewModel.cameraDenied = true
                            }
                        )
                        if viewModel.isLookingUp {
                            ProgressView("Looking up barcode")
                                .padding()
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                if let message = viewModel.lookupMessage {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                }

                Text("Point the camera at a barcode.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            }
            .navigationTitle("Scan")
            .navigationDestination(item: $viewModel.scannedItem) { item in
                ItemDetailView(item: item, listViewModel: listViewModel)
            }
            .onDisappear {
                viewModel.reset()
            }
        }
    }
}

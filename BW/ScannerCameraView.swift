import AVFoundation
import SwiftUI
import UIKit

/// The camera viewfinder, as a SwiftUI wrapper around
/// AVCaptureSession. v1 built the session in `viewDidLoad` with a
/// `try!` input, no permission check, and no stop path, and kept
/// a second, broken camera implementation in CameraVC/CameraSetup.
/// This is the only camera code in v2:
///
/// - Permission is requested before the session starts; a denied
///   permission reports back through `onPermissionDenied` instead
///   of silently showing a black viewfinder.
/// - The session starts when the view appears and stops when it
///   disappears, so scanning does not keep running in the
///   background after the user leaves the tab.
/// - Every detected code is forwarded to `onCode`; deduplication
///   and lookup live in `ScannerViewModel`, not in the delegate.
struct ScannerCameraView: UIViewControllerRepresentable {
    var onCode: (String) -> Void
    var onPermissionDenied: () -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onCode = onCode
        controller.onPermissionDenied = onPermissionDenied
        return controller
    }

    func updateUIViewController(
        _ controller: ScannerViewController,
        context: Context
    ) {}

    static func dismantleUIViewController(
        _ controller: ScannerViewController,
        coordinator: Void
    ) {
        controller.stopSession()
    }
}

final class ScannerViewController: UIViewController {
    var onCode: ((String) -> Void)?
    var onPermissionDenied: (() -> Void)?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let metadataDelegate = ScannerMetadataDelegate()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkPermissionAndStart()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession?.startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    func stopSession() {
        captureSession?.stopRunning()
    }

    private func checkPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startSession()
                    } else {
                        self?.onPermissionDenied?()
                    }
                }
            }
        case .denied, .restricted:
            onPermissionDenied?()
        @unknown default:
            onPermissionDenied?()
        }
    }

    private func startSession() {
        guard captureSession == nil else {
            captureSession?.startRunning()
            return
        }
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            // No camera (for example, the Simulator): the view
            // stays black and the parent view shows its own
            // "camera unavailable" state instead of crashing.
            return
        }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        metadataDelegate.onCode = onCode
        output.setMetadataObjectsDelegate(metadataDelegate, queue: .main)
        output.metadataObjectTypes = [
            .ean8, .ean13, .upce, .code39, .code93, .code128
        ]
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer
        captureSession = session
        session.startRunning()
    }

}

/// The capture-output delegate, kept separate from the view
/// controller on purpose. `AVCaptureMetadataOutputObjectsDelegate`
/// is a nonisolated ObjC protocol, while the view controller's
/// methods are main-actor-isolated, so conforming the controller
/// itself does not compile under Swift 6. This class is not
/// main-actor-isolated, so its method satisfies the protocol
/// requirement directly. It is still called on the main queue
/// (`setMetadataObjectsDelegate(_:queue: .main)` in
/// `startSession`), and the codes it forwards are handled on the
/// main actor by the caller's `Task` in `ScannerView`. The
/// controller retains this delegate; the capture output holds
/// it weakly.
final class ScannerMetadataDelegate: NSObject,
    AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        for object in metadataObjects {
            if let codeObject = object as? AVMetadataMachineReadableCodeObject,
               let value = codeObject.stringValue {
                onCode?(value)
            }
        }
    }
}

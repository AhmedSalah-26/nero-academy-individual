import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var secureTextField: UITextField?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // ── Screen Secure Channel ──────────────────────────────────────────
        let controller = window?.rootViewController as? FlutterViewController
        let channel = FlutterMethodChannel(
            name: "nero_academy/screen_secure",
            binaryMessenger: controller!.binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            guard call.method == "setScreenSecure" else {
                result(FlutterMethodNotImplemented)
                return
            }
            let enable = (call.arguments as? [String: Any])?["enable"] as? Bool ?? false
            DispatchQueue.main.async {
                self?.setScreenSecure(enable)
            }
            result(nil)
        }
        // ──────────────────────────────────────────────────────────────────

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: – Screen security helper
    // iOS approach: a secure UITextField creates a system-protected layer.
    // When the screen is captured, iOS blurs the content of the window.
    private func setScreenSecure(_ secure: Bool) {
        if secure {
            guard secureTextField == nil,
                  let rootView = window?.rootViewController?.view else { return }

            let field = UITextField()
            field.isSecureTextEntry = true
            field.isUserInteractionEnabled = false
            field.translatesAutoresizingMaskIntoConstraints = false

            rootView.addSubview(field)
            NSLayoutConstraint.activate([
                field.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
                field.centerYAnchor.constraint(equalTo: rootView.centerYAnchor),
                field.widthAnchor.constraint(equalToConstant: 1),
                field.heightAnchor.constraint(equalToConstant: 1),
            ])

            // Attach the window layer to the secure field's layer
            // so the entire window is protected from recording.
            if let secureLayer = field.layer.sublayers?.first {
                secureLayer.frame = rootView.frame
                rootView.layer.superlayer?.insertSublayer(secureLayer, at: 0)
                secureTextField = field
            }
        } else {
            secureTextField?.removeFromSuperview()
            secureTextField = nil
        }
    }
}

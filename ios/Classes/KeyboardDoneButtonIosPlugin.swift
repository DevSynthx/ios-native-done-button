import Flutter
import UIKit

public class SwiftKeyboardDoneButtonIosPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "keyboard_done_button_ios",
            binaryMessenger: registrar.messenger()
        )
        let instance = SwiftKeyboardDoneButtonIosPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "showDoneButton":
            let args = call.arguments as? [String: Any]
            let toolbarColor = args?["toolbarColor"] as? String
            let buttonColor  = args?["buttonColor"] as? String
            showDoneButton(toolbarHex: toolbarColor, buttonHex: buttonColor)
            result(nil)

        case "hideDoneButton":
            hideDoneButton()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func showDoneButton(toolbarHex: String?, buttonHex: String?) {
        // iPad has its own dismiss key — skip
        if UIDevice.current.userInterfaceIdiom == .pad { return }

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        // ── Toolbar background color ──────────────────────────────────
        let appearance = UIToolbarAppearance()
        appearance.configureWithOpaqueBackground()

        if let hex = toolbarHex, let color = colorFromHex(hex) {
            appearance.backgroundColor = color
        } else {
            // Fallback: match system grouped background (adapts to dark/light)
            appearance.backgroundColor = UIColor.systemGroupedBackground
        }

        toolbar.standardAppearance   = appearance
        toolbar.scrollEdgeAppearance = appearance

        // ── Done button ───────────────────────────────────────────────
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
        if let hex = buttonHex, let color = colorFromHex(hex) {
            doneButton.tintColor = color
        }

        let flexSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        toolbar.setItems([flexSpace, doneButton], animated: false)

        // Attach to the currently focused text field / view
        UIApplication.shared.sendAction(
            #selector(UIResponder.becomeFirstResponder),
            to: nil, from: nil, for: nil
        )
        if let firstResponder = UIApplication.shared.firstKeyWindow?.firstResponder {
            if let textField = firstResponder as? UITextField {
                textField.inputAccessoryView = toolbar
                textField.reloadInputViews()
            } else if let textView = firstResponder as? UITextView {
                textView.inputAccessoryView = toolbar
                textView.reloadInputViews()
            }
        }
    }

    private func hideDoneButton() {
        if let firstResponder = UIApplication.shared.firstKeyWindow?.firstResponder {
            if let textField = firstResponder as? UITextField {
                textField.inputAccessoryView = nil
                textField.reloadInputViews()
            } else if let textView = firstResponder as? UITextView {
                textView.inputAccessoryView = nil
                textView.reloadInputViews()
            }
        }
    }

    @objc private func doneButtonTapped() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    // MARK: - Helpers

    private func colorFromHex(_ hex: String) -> UIColor? {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h = String(h.dropFirst()) }
        guard h.count == 6, let rgb = UInt64(h, radix: 16) else { return nil }
        return UIColor(
            red:   CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8)  & 0xFF) / 255,
            blue:  CGFloat( rgb        & 0xFF) / 255,
            alpha: 1.0
        )
    }
}

// MARK: - UIWindow / firstResponder extensions

private extension UIApplication {
    var firstKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

private extension UIView {
    var firstResponder: UIView? {
        guard !isFirstResponder else { return self }
        return subviews.lazy.compactMap { $0.firstResponder }.first
    }
}
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
            print("🎨 showDoneButton args: \(String(describing: args))")
            let toolbarColor = args?["toolbarColor"] as? String
            let buttonColor  = args?["buttonColor"] as? String
            print("🎨 toolbarColor: \(String(describing: toolbarColor))")
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
    if UIDevice.current.userInterfaceIdiom == .pad { return }

    let toolbar = UIToolbar()
    toolbar.sizeToFit()

    // ✅ Set on the instance directly, NOT UIToolbar.appearance()
    if #available(iOS 15.0, *) {
        let appearance = UIToolbarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = toolbarHex.flatMap { colorFromHex($0) }
            ?? UIColor.systemGroupedBackground
        toolbar.standardAppearance   = appearance
        toolbar.scrollEdgeAppearance = appearance
    } else {
        // iOS 14 fallback
        toolbar.barTintColor = toolbarHex.flatMap { colorFromHex($0) }
            ?? UIColor.systemGroupedBackground
        toolbar.isTranslucent = false
    }

    // Done button
    let doneButton = UIBarButtonItem(
        barButtonSystemItem: .done,
        target: self,
        action: #selector(doneButtonTapped)
    )
    doneButton.tintColor = buttonHex.flatMap { colorFromHex($0) } ?? UIColor.systemBlue

    let flexSpace = UIBarButtonItem(
        barButtonSystemItem: .flexibleSpace,
        target: nil, action: nil
    )
    toolbar.setItems([flexSpace, doneButton], animated: false)

    // Attach to first responder
    DispatchQueue.main.async {
        if let firstResponder = self.findFirstResponder() {
            if let tf = firstResponder as? UITextField {
                tf.inputAccessoryView = toolbar
                tf.reloadInputViews()
            } else if let tv = firstResponder as? UITextView {
                tv.inputAccessoryView = toolbar
                tv.reloadInputViews()
            }
        }
    }
}

private func findFirstResponder() -> UIResponder? {
    return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?
        .rootViewController?.view.findFirstResponder()
}

  private func hideDoneButton() {
    DispatchQueue.main.async {
        if let firstResponder = self.findFirstResponder() {
            if let textField = firstResponder as? UITextField {
                textField.inputAccessoryView = nil
                textField.reloadInputViews()
            } else if let textView = firstResponder as? UITextView {
                textView.inputAccessoryView = nil
                textView.reloadInputViews()
            }
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

// MARK: - UIWindow / firstResponder extension

extension UIView {
    func findFirstResponder() -> UIView? {
        if isFirstResponder { return self }
        return subviews.lazy.compactMap { $0.findFirstResponder() }.first
    }
}
import Flutter
import UIKit

public class KeyboardDoneButtonIosPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "keyboard_done_button_ios",
            binaryMessenger: registrar.messenger()
        )
        let instance = KeyboardDoneButtonIosPlugin()
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

    private var toolbar: UIToolbar?

    private func showDoneButton(toolbarHex: String?, buttonHex: String?) {
        if UIDevice.current.userInterfaceIdiom == .pad { return }

        let bar = UIToolbar()
        bar.sizeToFit()
        bar.barTintColor = toolbarHex.flatMap { colorFromHex($0) } ?? UIColor.systemGroupedBackground
        bar.isTranslucent = false

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
        bar.setItems([flexSpace, doneButton], animated: false)
        self.toolbar = bar

        // This is how the original plugin works — post to FlutterTextInputPlugin
        NotificationCenter.default.post(
            name: UITextField.textDidBeginEditingNotification,
            object: nil
        )

        DispatchQueue.main.async {
            self.attachToCurrentResponder()
        }
    }

    private func attachToCurrentResponder() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        attachToolbar(self.toolbar, in: window)
    }

    private func attachToolbar(_ toolbar: UIToolbar?, in view: UIView) {
        for subview in view.subviews {
            let name = String(describing: type(of: subview))
            if name.contains("FlutterTextInput") {
                subview.perform(Selector(("setInputAccessoryView:")), with: toolbar)
                subview.reloadInputViews()
                return
            }
            attachToolbar(toolbar, in: subview)
        }
    }

    private func hideDoneButton() {
        self.toolbar = nil
        DispatchQueue.main.async {
            self.attachToCurrentResponder()
        }
    }

    @objc private func doneButtonTapped() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

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
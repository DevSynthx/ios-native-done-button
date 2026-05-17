import Flutter
import UIKit

public class KeyboardDoneButtonIosPlugin: NSObject, FlutterPlugin {

  // MARK: - Properties

  private var toolbarWindow: UIWindow?
  private var toolbar: UIToolbar?
  private var pendingToolbarRequest = false
  private var isObserversRegistered = false
  private var isToolbarActive = false
  private var lastScreenBounds: CGRect = .zero
  private var toolbarHex: String?  // 👈
  private var buttonHex: String?   // 👈

  // MARK: - Plugin Registration

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "keyboard_done_button_ios",
      binaryMessenger: registrar.messenger())

    let instance = KeyboardDoneButtonIosPlugin()
    instance.registerKeyboardObservers()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  // MARK: - Flutter Method Handler

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "showDoneButton":
      let args = call.arguments as? [String: Any]  // 👈
      toolbarHex = args?["toolbarColor"] as? String // 👈
      buttonHex  = args?["buttonColor"] as? String  // 👈
      showDoneButton()
      result(true)
    case "hideDoneButton":
      hideDoneButton()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Setup

  private func registerKeyboardObservers() {
    guard UIDevice.current.userInterfaceIdiom != .pad else { return }
    guard !isObserversRegistered else { return }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow(_:)),
      name: UIResponder.keyboardWillShowNotification,
      object: nil)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillHide(_:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil)

    isObserversRegistered = true
  }

  private func showDoneButton() {
    guard UIDevice.current.userInterfaceIdiom != .pad else { return }
    toolbar = nil  // 👈 force recreate with new colors
    pendingToolbarRequest = true
  }

  private func hideDoneButton() {
    guard UIDevice.current.userInterfaceIdiom != .pad else { return }
    pendingToolbarRequest = false
    isToolbarActive = false
    hideToolbar()
  }

  // MARK: - Keyboard Handlers

  @objc private func keyboardWillShow(_ notification: Notification) {
    guard
      let keyboardFrameEnd = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
        as? CGRect
    else { return }

    let currentScreenBounds = UIScreen.main.bounds
    let didRotate =
      isToolbarActive && lastScreenBounds != .zero && lastScreenBounds != currentScreenBounds
    lastScreenBounds = currentScreenBounds

    let shouldShowToolbar = pendingToolbarRequest || didRotate || isToolbarActive
    pendingToolbarRequest = false

    guard shouldShowToolbar else {
      isToolbarActive = false
      hideToolbar()
      return
    }

    guard
      let animationDuration = notification.userInfo?[
        UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
      let animationCurveRaw = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey]
        as? NSNumber
    else { return }

    let animationCurve = UIView.AnimationOptions(rawValue: animationCurveRaw.uintValue << 16)

    isToolbarActive = true
    showToolbar(
      toKeyboardFrame: keyboardFrameEnd,
      duration: animationDuration,
      animationCurve: animationCurve)
  }

  @objc private func keyboardWillHide(_ notification: Notification) {
    let duration =
      notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
      ?? 0.25
    hideToolbar(duration: duration)
  }

  // MARK: - Toolbar Creation

  private func createToolbar() -> UIToolbar {
    let toolbar = UIToolbar()
    toolbar.barStyle = .default
    toolbar.barTintColor = toolbarHex.flatMap { colorFromHex($0) } ?? UIColor.systemGroupedBackground  // 👈
    toolbar.isTranslucent = false                                                                      // 👈
    toolbar.autoresizingMask = [.flexibleWidth]

    let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let doneButton = UIBarButtonItem(
      barButtonSystemItem: .done,
      target: self,
      action: #selector(doneButtonTapped))
    doneButton.tintColor = buttonHex.flatMap { colorFromHex($0) } ?? UIColor.systemBlue  // 👈
    let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
    fixedSpace.width = 16

    toolbar.items = [flexSpace, doneButton, fixedSpace]
    toolbar.sizeToFit()
    return toolbar
  }

  // MARK: - Show & Hide Toolbar

  private func showToolbar(
    toKeyboardFrame endFrame: CGRect,
    duration: TimeInterval,
    animationCurve: UIView.AnimationOptions
  ) {
    if toolbar == nil {
      toolbar = createToolbar()
    }

    if toolbarWindow == nil {
      let window: UIWindow
      if #available(iOS 13.0, *),
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
      {
        window = UIWindow(windowScene: windowScene)
      } else {
        window = UIWindow(frame: .zero)
      }

      window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.alert.rawValue - 1)
      window.backgroundColor = .clear
      window.isUserInteractionEnabled = true
      toolbarWindow = window
    } else {
      toolbarWindow?.layer.removeAllAnimations()
    }

    guard let toolbarWindow = toolbarWindow, let toolbar = toolbar else { return }

    let screenWidth = UIScreen.main.bounds.width
    let toolbarHeight = toolbar.frame.height
    let finalY = endFrame.origin.y - toolbarHeight

    if toolbar.superview == nil {
      toolbar.frame = CGRect(x: 0, y: 0, width: screenWidth, height: toolbarHeight)
      toolbarWindow.addSubview(toolbar)
    }

    let isAlreadyVisible = !toolbarWindow.isHidden && toolbarWindow.alpha == 1
    if isAlreadyVisible {
      toolbarWindow.frame = CGRect(x: 0, y: finalY, width: screenWidth, height: toolbarHeight)
      return
    }

    UIView.performWithoutAnimation {
      toolbarWindow.frame = CGRect(x: 0, y: finalY, width: screenWidth, height: toolbarHeight)
      toolbarWindow.alpha = 0
      toolbarWindow.isHidden = false
    }

    UIView.animate(
      withDuration: duration,
      delay: 0,
      options: [animationCurve],
      animations: { toolbarWindow.alpha = 1 },
      completion: nil)
  }

  private func hideToolbar(duration: TimeInterval = 0.25) {
    guard let toolbarWindow = toolbarWindow else { return }

    UIView.animate(
      withDuration: duration,
      animations: { toolbarWindow.alpha = 0 }
    ) { finished in
      guard finished else { return }
      toolbarWindow.isHidden = true
    }
  }

  // MARK: - Button Actions

  @objc private func doneButtonTapped() {
    isToolbarActive = false
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder),
      to: nil, from: nil, for: nil)
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
      alpha: 1.0)
  }

  // MARK: - Deinitialization

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
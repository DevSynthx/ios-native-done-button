import 'dart:io';
import 'package:flutter/widgets.dart';
import 'keyboard_done_button_ios_platform_interface.dart';

class KeyboardToolbar {
  static Future<void> show({String? toolbarColor, String? buttonColor}) async {
    if (Platform.isIOS) {
      await KeyboardDoneButtonIosPlatform.instance.showDoneButton(
        toolbarColor: toolbarColor,
        buttonColor: buttonColor,
      );
    }
  }

  static Future<void> hide() async {
    if (Platform.isIOS) {
      await KeyboardDoneButtonIosPlatform.instance.hideDoneButton();
    }
  }
}

class KeyboardToolbarField extends StatefulWidget {
  final Widget child;
  final bool showToolbar;
  final FocusNode? focusNode;
  final String? toolbarColor; // 👈 new
  final String? buttonColor; // 👈 new

  const KeyboardToolbarField({
    super.key,
    required this.child,
    this.showToolbar = true,
    this.focusNode,
    this.toolbarColor, // 👈 new
    this.buttonColor, // 👈 new
  });

  @override
  State<KeyboardToolbarField> createState() => _KeyboardToolbarFieldState();
}

class _KeyboardToolbarFieldState extends State<KeyboardToolbarField> {
  late FocusNode _focusNode;
  bool _ownsNode = false;

  @override
  void initState() {
    super.initState();
    _initFocusNode();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _initFocusNode() {
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsNode = false;
    } else {
      _focusNode = FocusNode();
      _ownsNode = true;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(KeyboardToolbarField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (_ownsNode) _focusNode.dispose();
      _initFocusNode();
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (widget.showToolbar) {
        KeyboardToolbar.show(
          toolbarColor: widget.toolbarColor,
          buttonColor: widget.buttonColor,
        );
      } else {
        KeyboardToolbar.hide();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(focusNode: _focusNode, child: widget.child);
  }
}

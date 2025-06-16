import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper widget that makes any dialog dismissible with the ESC key
class EscDismissibleDialog extends StatelessWidget {
  const EscDismissibleDialog({
    super.key,
    required this.child,
    this.onEscPressed,
  });

  final Widget child;
  final VoidCallback? onEscPressed;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          if (onEscPressed != null) {
            onEscPressed!();
          } else {
            Navigator.of(context).pop();
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

/// Extension to easily show ESC-dismissible dialogs
extension EscDismissibleDialogExtension on BuildContext {
  /// Show a dialog that can be dismissed with ESC key
  Future<T?> showEscDismissibleDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
    VoidCallback? onEscPressed,
  }) {
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
      builder: (context) => EscDismissibleDialog(
        onEscPressed: onEscPressed,
        child: builder(context),
      ),
    );
  }
}

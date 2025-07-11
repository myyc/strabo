import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:io' show Platform;

class CustomWindowFrame extends StatelessWidget {
  final Widget child;
  final String title;

  const CustomWindowFrame({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return child;
    }

    return Column(
      children: [
        WindowTitleBarBox(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(child: MoveWindow()),
                const WindowButtons(),
              ],
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(
          colors: WindowButtonColors(
            iconNormal: Theme.of(context).colorScheme.onSurface,
            mouseOver: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            mouseDown: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
        MaximizeWindowButton(
          colors: WindowButtonColors(
            iconNormal: Theme.of(context).colorScheme.onSurface,
            mouseOver: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            mouseDown: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
        CloseWindowButton(
          colors: WindowButtonColors(
            iconNormal: Theme.of(context).colorScheme.onSurface,
            mouseOver: Colors.red.withOpacity(0.1),
            mouseDown: Colors.red.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}
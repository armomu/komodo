import 'package:flutter/material.dart';

class WidgetVisibilityInfo {
  final double visibleFraction;
  const WidgetVisibilityInfo(this.visibleFraction);
}

typedef VisibilityChangedCallback = void Function(WidgetVisibilityInfo);

class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final VisibilityChangedCallback onVisibilityChanged;

  const VisibilityDetector({
    super.key,
    required this.child,
    required this.onVisibilityChanged,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onVisibilityChanged(const WidgetVisibilityInfo(1.0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

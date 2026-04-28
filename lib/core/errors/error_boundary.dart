import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({required this.child, super.key});

  final Widget child;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  void Function(FlutterErrorDetails)? _defaultOnError;

  @override
  void initState() {
    super.initState();
    _defaultOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      _defaultOnError?.call(details);
    };
  }

  @override
  void dispose() {
    FlutterError.onError = _defaultOnError;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (details) {
      return Material(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              details.exceptionAsString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    };
    return widget.child;
  }
}

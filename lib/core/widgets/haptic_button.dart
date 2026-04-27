import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HapticButton extends StatelessWidget {
  const HapticButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      icon: Icon(icon ?? Icons.check_circle_outline),
      label: Text(label),
    );
  }
}

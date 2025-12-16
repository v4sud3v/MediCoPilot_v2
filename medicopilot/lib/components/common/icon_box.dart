import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Icon box widget for displaying icons in colored containers
class IconBox extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;

  const IconBox({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.size = 48,
    this.iconSize = 24,
  });

  /// Blue icon box
  factory IconBox.blue(IconData icon, {double size = 48, double iconSize = 24}) {
    return IconBox(
      icon: icon,
      backgroundColor: AppTheme.blueLight,
      iconColor: AppTheme.blue,
      size: size,
      iconSize: iconSize,
    );
  }

  /// Purple icon box
  factory IconBox.purple(IconData icon, {double size = 48, double iconSize = 24}) {
    return IconBox(
      icon: icon,
      backgroundColor: AppTheme.purpleLight,
      iconColor: AppTheme.purple,
      size: size,
      iconSize: iconSize,
    );
  }

  /// Green icon box
  factory IconBox.green(IconData icon, {double size = 48, double iconSize = 24}) {
    return IconBox(
      icon: icon,
      backgroundColor: AppTheme.greenLight,
      iconColor: AppTheme.green,
      size: size,
      iconSize: iconSize,
    );
  }

  /// Amber icon box
  factory IconBox.amber(IconData icon, {double size = 48, double iconSize = 24}) {
    return IconBox(
      icon: icon,
      backgroundColor: AppTheme.amberLight,
      iconColor: AppTheme.amber,
      size: size,
      iconSize: iconSize,
    );
  }

  /// Red icon box
  factory IconBox.red(IconData icon, {double size = 48, double iconSize = 24}) {
    return IconBox(
      icon: icon,
      backgroundColor: AppTheme.redLight,
      iconColor: AppTheme.red,
      size: size,
      iconSize: iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: iconSize,
      ),
    );
  }
}

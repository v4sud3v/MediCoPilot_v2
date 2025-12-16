import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Reusable status badge widget
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  /// Create a badge for encounter status
  factory StatusBadge.encounterStatus(String status) {
    Color bgColor;
    Color txtColor;

    switch (status.toLowerCase()) {
      case 'finalized':
        bgColor = AppTheme.greenLight;
        txtColor = AppTheme.green;
        break;
      case 'pending review':
      case 'pending-review':
        bgColor = AppTheme.amberLight;
        txtColor = AppTheme.amber;
        break;
      case 'in progress':
      case 'in-progress':
        bgColor = AppTheme.blueLight;
        txtColor = AppTheme.blue;
        break;
      default:
        bgColor = AppTheme.surfaceVariant;
        txtColor = AppTheme.textSecondary;
    }

    return StatusBadge(
      label: status,
      backgroundColor: bgColor,
      textColor: txtColor,
    );
  }

  /// Create a badge for urgency level
  factory StatusBadge.urgency(String urgency) {
    Color bgColor;
    Color txtColor;

    switch (urgency.toLowerCase()) {
      case 'high':
        bgColor = AppTheme.redLight;
        txtColor = AppTheme.red;
        break;
      case 'medium':
        bgColor = AppTheme.amberLight;
        txtColor = AppTheme.amber;
        break;
      case 'low':
        bgColor = AppTheme.blueLight;
        txtColor = AppTheme.blue;
        break;
      default:
        bgColor = AppTheme.surfaceVariant;
        txtColor = AppTheme.textSecondary;
    }

    return StatusBadge(
      label: '$urgency priority',
      backgroundColor: bgColor,
      textColor: txtColor,
    );
  }

  /// Create a badge for event type
  factory StatusBadge.eventType(String eventType) {
    Color bgColor;
    Color txtColor;

    switch (eventType.toLowerCase()) {
      case 'follow-up':
        bgColor = AppTheme.blueLight;
        txtColor = AppTheme.blue;
        break;
      case 'test':
        bgColor = AppTheme.purpleLight;
        txtColor = AppTheme.purple;
        break;
      case 'medication':
        bgColor = AppTheme.greenLight;
        txtColor = AppTheme.green;
        break;
      default:
        bgColor = AppTheme.surfaceVariant;
        txtColor = AppTheme.textSecondary;
    }

    return StatusBadge(
      label: eventType,
      backgroundColor: bgColor,
      textColor: txtColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

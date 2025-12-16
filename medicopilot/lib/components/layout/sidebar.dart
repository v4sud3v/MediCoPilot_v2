import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Navigation item model
class NavigationItem {
  final String id;
  final String label;
  final IconData icon;

  const NavigationItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// Sidebar widget for the main navigation
class Sidebar extends StatelessWidget {
  final String activeSection;
  final Function(String) onNavigate;

  const Sidebar({
    super.key,
    required this.activeSection,
    required this.onNavigate,
  });

  static const List<NavigationItem> navigationItems = [
    NavigationItem(id: 'dashboard', label: 'Dashboard', icon: Icons.home_outlined),
    NavigationItem(id: 'new-encounter', label: 'New Encounter', icon: Icons.note_add_outlined),
    NavigationItem(id: 'encounters', label: 'All Encounters', icon: Icons.list_alt_outlined),
    NavigationItem(id: 'suggestions', label: 'Suggestions', icon: Icons.checklist_outlined),
    NavigationItem(id: 'summaries', label: 'Patient Summaries', icon: Icons.people_outline),
    NavigationItem(id: 'uploads', label: 'File Uploads', icon: Icons.upload_file_outlined),
    NavigationItem(id: 'reminders', label: 'Reminders', icon: Icons.calendar_month_outlined),
    NavigationItem(id: 'settings', label: 'Settings', icon: Icons.settings_outlined),
    NavigationItem(id: 'help', label: 'Help', icon: Icons.help_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: AppTheme.sidebarBg,
        border: Border(
          right: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clinical Dashboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryBlue,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Dr. Smith's Practice",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),

          // Navigation
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: navigationItems.map((item) {
                  final isActive = activeSection == item.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onNavigate(item.id),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.sidebarActive
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: isActive
                                    ? AppTheme.sidebarActiveText
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: isActive
                                      ? AppTheme.sidebarActiveText
                                      : AppTheme.textPrimary,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // User profile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.border),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.blueLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'DS',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. Smith',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'doctor@clinic.com',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

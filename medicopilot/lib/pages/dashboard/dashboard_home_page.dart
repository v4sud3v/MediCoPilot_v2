import 'package:flutter/material.dart';
import '../../components/common/common.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/mock_data.dart';

/// Dashboard home page showing overview statistics
class DashboardHomePage extends StatelessWidget {
  final Function(String) onNavigate;

  const DashboardHomePage({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final pendingEncounters = MockData.encounters
        .where((e) => e.status == EncounterStatus.pendingReview)
        .length;
    final pendingSuggestions =
        MockData.suggestions.where((s) => s.status == SuggestionStatus.pending).length;
    final upcomingReminders = MockData.reminders.where((r) => !r.completed).length;
    final totalEncounters = MockData.encounters.length;

    final recentEncounters = MockData.encounters.take(3).toList();
    final upcomingRemindersList =
        MockData.reminders.where((r) => !r.completed).take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header
          Text(
            'Welcome back, Dr. Smith',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            "Here's what's happening with your patients today.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // Stats grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200
                  ? 4
                  : constraints.maxWidth > 800
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
                children: [
                  StatCard(
                    title: 'Pending Review',
                    value: '$pendingEncounters',
                    icon: IconBox.blue(Icons.description_outlined),
                    onTap: () => onNavigate('encounters'),
                  ),
                  StatCard(
                    title: 'AI Suggestions',
                    value: '$pendingSuggestions',
                    icon: IconBox.amber(Icons.warning_amber_outlined),
                    onTap: () => onNavigate('suggestions'),
                  ),
                  StatCard(
                    title: 'Upcoming Reminders',
                    value: '$upcomingReminders',
                    icon: IconBox.green(Icons.calendar_today_outlined),
                    onTap: () => onNavigate('reminders'),
                  ),
                  StatCard(
                    title: 'Total Encounters',
                    value: '$totalEncounters',
                    icon: IconBox.purple(Icons.people_outline),
                    onTap: () => onNavigate('encounters'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Recent encounters & reminders
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _RecentEncountersCard(
                        encounters: recentEncounters,
                        onNavigate: onNavigate,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _UpcomingRemindersCard(
                        reminders: upcomingRemindersList,
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _RecentEncountersCard(
                    encounters: recentEncounters,
                    onNavigate: onNavigate,
                  ),
                  const SizedBox(height: 24),
                  _UpcomingRemindersCard(
                    reminders: upcomingRemindersList,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Quick actions
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800
                  ? 3
                  : constraints.maxWidth > 500
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3,
                children: [
                  _QuickActionCard(
                    icon: Icons.note_add_outlined,
                    iconColor: AppTheme.blue,
                    iconBgColor: AppTheme.blueLight,
                    title: 'New Encounter',
                    subtitle: 'Start patient intake',
                    onTap: () => onNavigate('new-encounter'),
                  ),
                  _QuickActionCard(
                    icon: Icons.warning_amber_outlined,
                    iconColor: AppTheme.amber,
                    iconBgColor: AppTheme.amberLight,
                    title: 'Review Suggestions',
                    subtitle: 'Check AI recommendations',
                    onTap: () => onNavigate('suggestions'),
                  ),
                  _QuickActionCard(
                    icon: Icons.calendar_month_outlined,
                    iconColor: AppTheme.green,
                    iconBgColor: AppTheme.greenLight,
                    title: 'Manage Schedule',
                    subtitle: 'View reminders',
                    onTap: () => onNavigate('reminders'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Recent encounters card widget
class _RecentEncountersCard extends StatelessWidget {
  final List<Encounter> encounters;
  final Function(String) onNavigate;

  const _RecentEncountersCard({
    required this.encounters,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Encounters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...encounters.map((encounter) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => onNavigate('encounters'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  encounter.patientName,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  encounter.chiefComplaint,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatDate(encounter.encounterDate),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          StatusBadge.encounterStatus(encounter.status.displayName),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} at ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}

/// Upcoming reminders card widget
class _UpcomingRemindersCard extends StatelessWidget {
  final List<Reminder> reminders;

  const _UpcomingRemindersCard({
    required this.reminders,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Reminders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...reminders.map((reminder) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconBox.blue(
                          Icons.calendar_today_outlined,
                          size: 40,
                          iconSize: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reminder.patientName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reminder.notes,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_formatDate(reminder.date)} at ${reminder.time}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        StatusBadge.eventType(reminder.eventType.displayName),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Quick action card widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

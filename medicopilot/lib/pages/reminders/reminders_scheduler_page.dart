import 'package:flutter/material.dart';
import '../../components/common/common.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/mock_data.dart';

/// Reminders scheduler page for managing patient reminders
class RemindersSchedulerPage extends StatefulWidget {
  final List<Reminder> reminders;
  final Function(Reminder) onAddReminder;
  final Function(String) onToggleComplete;
  final Function(String) onDeleteReminder;

  const RemindersSchedulerPage({
    super.key,
    required this.reminders,
    required this.onAddReminder,
    required this.onToggleComplete,
    required this.onDeleteReminder,
  });

  @override
  State<RemindersSchedulerPage> createState() => _RemindersSchedulerPageState();
}

class _RemindersSchedulerPageState extends State<RemindersSchedulerPage> {
  void _showAddReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddReminderDialog(
        onAdd: widget.onAddReminder,
      ),
    );
  }

  List<Reminder> get _upcomingReminders => widget.reminders
      .where((r) => !r.completed)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  List<Reminder> get _completedReminders => widget.reminders
      .where((r) => r.completed)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  bool _isOverdue(Reminder reminder) {
    if (reminder.completed) return false;
    final now = DateTime.now();
    final parts = reminder.time.split(':');
    final reminderDateTime = DateTime(
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    return reminderDateTime.isBefore(now);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminders & Scheduling',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage patient follow-ups and appointments',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddReminderDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Reminder'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Reminders grid
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _RemindersCard(
                        title: 'Upcoming Reminders (${_upcomingReminders.length})',
                        reminders: _upcomingReminders,
                        emptyIcon: Icons.calendar_month,
                        emptyMessage: 'No upcoming reminders',
                        onToggle: widget.onToggleComplete,
                        onDelete: widget.onDeleteReminder,
                        isOverdue: _isOverdue,
                        showCheckbox: true,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _RemindersCard(
                        title: 'Completed (${_completedReminders.length})',
                        reminders: _completedReminders,
                        emptyIcon: Icons.check_circle_outline,
                        emptyMessage: 'No completed reminders',
                        onToggle: widget.onToggleComplete,
                        onDelete: widget.onDeleteReminder,
                        isOverdue: _isOverdue,
                        showCheckbox: false,
                        isCompleted: true,
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _RemindersCard(
                    title: 'Upcoming Reminders (${_upcomingReminders.length})',
                    reminders: _upcomingReminders,
                    emptyIcon: Icons.calendar_month,
                    emptyMessage: 'No upcoming reminders',
                    onToggle: widget.onToggleComplete,
                    onDelete: widget.onDeleteReminder,
                    isOverdue: _isOverdue,
                    showCheckbox: true,
                  ),
                  const SizedBox(height: 24),
                  _RemindersCard(
                    title: 'Completed (${_completedReminders.length})',
                    reminders: _completedReminders,
                    emptyIcon: Icons.check_circle_outline,
                    emptyMessage: 'No completed reminders',
                    onToggle: widget.onToggleComplete,
                    onDelete: widget.onDeleteReminder,
                    isOverdue: _isOverdue,
                    showCheckbox: false,
                    isCompleted: true,
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

/// Reminders card widget
class _RemindersCard extends StatelessWidget {
  final String title;
  final List<Reminder> reminders;
  final IconData emptyIcon;
  final String emptyMessage;
  final Function(String) onToggle;
  final Function(String) onDelete;
  final bool Function(Reminder) isOverdue;
  final bool showCheckbox;
  final bool isCompleted;

  const _RemindersCard({
    required this.title,
    required this.reminders,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.onToggle,
    required this.onDelete,
    required this.isOverdue,
    required this.showCheckbox,
    this.isCompleted = false,
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
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (reminders.isEmpty)
              EmptyState(
                icon: emptyIcon,
                title: emptyMessage,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reminders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  final overdue = isOverdue(reminder);
                  return _ReminderItem(
                    reminder: reminder,
                    isOverdue: overdue,
                    showCheckbox: showCheckbox,
                    isCompleted: isCompleted,
                    onToggle: () => onToggle(reminder.id),
                    onDelete: () => onDelete(reminder.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Reminder item widget
class _ReminderItem extends StatelessWidget {
  final Reminder reminder;
  final bool isOverdue;
  final bool showCheckbox;
  final bool isCompleted;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ReminderItem({
    required this.reminder,
    required this.isOverdue,
    required this.showCheckbox,
    required this.isCompleted,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppTheme.surfaceVariant.withValues(alpha: 0.5)
            : isOverdue
                ? AppTheme.redLight
                : null,
        border: Border.all(
          color: isOverdue ? AppTheme.red.withValues(alpha: 0.3) : AppTheme.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCheckbox) ...[
            InkWell(
              onTap: onToggle,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Opacity(
              opacity: isCompleted ? 0.6 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        reminder.patientName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      StatusBadge.eventType(reminder.eventType.displayName),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reminder.notes,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reminder.date.month}/${reminder.date.day}/${reminder.date.year}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reminder.time,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  if (isOverdue) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Overdue',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.red,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppTheme.red),
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

/// Add reminder dialog
class _AddReminderDialog extends StatefulWidget {
  final Function(Reminder) onAdd;

  const _AddReminderDialog({required this.onAdd});

  @override
  State<_AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<_AddReminderDialog> {
  String? _selectedPatientId;
  ReminderEventType _eventType = ReminderEventType.followUp;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final patient =
        MockData.patients.firstWhere((p) => p.id == _selectedPatientId);

    final reminder = Reminder(
      id: 'R${DateTime.now().millisecondsSinceEpoch}',
      patientId: patient.id,
      patientName: patient.name,
      eventType: _eventType,
      date: _selectedDate,
      time: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      notes: _notesController.text,
      completed: false,
    );

    widget.onAdd(reminder);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder added successfully'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Reminder',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // Patient selection
            Text(
              'Patient *',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPatientId,
              decoration: const InputDecoration(
                hintText: 'Select a patient',
              ),
              items: MockData.patients.map((patient) {
                return DropdownMenuItem(
                  value: patient.id,
                  child: Text(patient.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPatientId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Event type
            Text(
              'Event Type *',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReminderEventType>(
              value: _eventType,
              items: ReminderEventType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _eventType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Date picker
            Text(
              'Date *',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                  '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}'),
            ),
            const SizedBox(height: 16),

            // Time picker
            Text(
              'Time *',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
              icon: const Icon(Icons.access_time),
              label: Text(_selectedTime.format(context)),
            ),
            const SizedBox(height: 16),

            // Notes
            AppTextField(
              label: 'Notes',
              hint: 'Additional details about this reminder...',
              controller: _notesController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: const Text('Add Reminder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

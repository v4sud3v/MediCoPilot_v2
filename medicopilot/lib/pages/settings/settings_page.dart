import 'package:flutter/material.dart';
import '../../components/common/common.dart';
import '../../theme/app_theme.dart';

/// Settings page for managing account and preferences
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController(text: 'Dr. Smith');
  final _emailController = TextEditingController(text: 'doctor@clinic.com');
  final _phoneController = TextEditingController(text: '(555) 123-4567');
  final _specialtyController = TextEditingController(text: 'Internal Medicine');
  final _licenseController = TextEditingController(text: 'MD-12345');

  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _suggestionAlerts = true;
  bool _reminderAlerts = true;
  bool _autoSaveEncounters = true;
  bool _darkMode = false;

  void _handleSaveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _handleSavePreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences saved'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your account and preferences',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // Profile Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconBox.blue(Icons.person_outline, size: 48, iconSize: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Information',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Update your personal details',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'Full Name',
                                    controller: _nameController,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppTextField(
                                    label: 'Email',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'Phone',
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppTextField(
                                    label: 'Specialty',
                                    controller: _specialtyController,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'License Number',
                                    controller: _licenseController,
                                  ),
                                ),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          AppTextField(
                            label: 'Full Name',
                            controller: _nameController,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Phone',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Specialty',
                            controller: _specialtyController,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'License Number',
                            controller: _licenseController,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _handleSaveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Profile'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Notifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconBox.purple(Icons.notifications_outlined,
                          size: 48, iconSize: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Configure how you receive alerts',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSwitch(
                    title: 'Email Notifications',
                    subtitle: 'Receive email alerts for important events',
                    value: _emailNotifications,
                    onChanged: (value) =>
                        setState(() => _emailNotifications = value),
                  ),
                  const Divider(),
                  _SettingsSwitch(
                    title: 'Push Notifications',
                    subtitle: 'Get push notifications in your browser',
                    value: _pushNotifications,
                    onChanged: (value) =>
                        setState(() => _pushNotifications = value),
                  ),
                  const Divider(),
                  _SettingsSwitch(
                    title: 'AI Suggestion Alerts',
                    subtitle: 'Get notified when AI generates new suggestions',
                    value: _suggestionAlerts,
                    onChanged: (value) =>
                        setState(() => _suggestionAlerts = value),
                  ),
                  const Divider(),
                  _SettingsSwitch(
                    title: 'Reminder Alerts',
                    subtitle: 'Get alerts for upcoming appointments',
                    value: _reminderAlerts,
                    onChanged: (value) =>
                        setState(() => _reminderAlerts = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Application Preferences
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconBox.green(Icons.tune, size: 48, iconSize: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Application Preferences',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Customize your workflow',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSwitch(
                    title: 'Auto-save Encounters',
                    subtitle: 'Automatically save draft encounters',
                    value: _autoSaveEncounters,
                    onChanged: (value) =>
                        setState(() => _autoSaveEncounters = value),
                  ),
                  const Divider(),
                  _SettingsSwitch(
                    title: 'Dark Mode',
                    subtitle: 'Use dark theme for the interface',
                    value: _darkMode,
                    onChanged: (value) => setState(() => _darkMode = value),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _handleSavePreferences,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Preferences'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings switch widget
class _SettingsSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

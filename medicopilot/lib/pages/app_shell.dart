import 'package:flutter/material.dart';
import '../components/layout/layout.dart';
import '../pages/pages.dart';
import '../models/models.dart';
import '../services/mock_data.dart';

/// Main app shell with sidebar navigation
class AppShell extends StatefulWidget {
  final VoidCallback onLogout;

  const AppShell({
    super.key,
    required this.onLogout,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String _activeSection = 'dashboard';
  Encounter? _selectedEncounter;

  // Mutable data lists
  late List<Encounter> _encounters;
  late List<AISuggestion> _suggestions;
  late List<UploadedFile> _uploadedFiles;
  late List<Reminder> _reminders;

  @override
  void initState() {
    super.initState();
    // Initialize with mock data
    _encounters = List.from(MockData.encounters);
    _suggestions = List.from(MockData.suggestions);
    _uploadedFiles = List.from(MockData.uploadedFiles);
    _reminders = List.from(MockData.reminders);
  }

  void _handleNavigate(String section) {
    setState(() {
      _activeSection = section;
      _selectedEncounter = null;
    });
  }

  void _handleViewEncounter(Encounter encounter) {
    setState(() {
      _selectedEncounter = encounter;
      _activeSection = 'encounter-detail';
    });
  }

  void _handleAddEncounter(Encounter encounter) {
    setState(() {
      _encounters.insert(0, encounter);
      _activeSection = 'encounters';
    });
  }

  void _handleUpdateSuggestion(String id, SuggestionStatus status) {
    setState(() {
      final index = _suggestions.indexWhere((s) => s.id == id);
      if (index != -1) {
        _suggestions[index] = _suggestions[index].copyWith(status: status);
      }
    });
  }

  void _handleAddFile(UploadedFile file) {
    setState(() {
      _uploadedFiles.add(file);
    });
  }

  void _handleDeleteFile(String fileId) {
    setState(() {
      _uploadedFiles.removeWhere((f) => f.id == fileId);
    });
  }

  void _handleAddReminder(Reminder reminder) {
    setState(() {
      _reminders.add(reminder);
    });
  }

  void _handleToggleReminder(String reminderId) {
    setState(() {
      final index = _reminders.indexWhere((r) => r.id == reminderId);
      if (index != -1) {
        _reminders[index] = _reminders[index].copyWith(
          completed: !_reminders[index].completed,
        );
      }
    });
  }

  void _handleDeleteReminder(String reminderId) {
    setState(() {
      _reminders.removeWhere((r) => r.id == reminderId);
    });
  }

  int get _pendingSuggestions =>
      _suggestions.where((s) => s.status == SuggestionStatus.pending).length;

  Widget _buildContent() {
    switch (_activeSection) {
      case 'dashboard':
        return DashboardHomePage(onNavigate: _handleNavigate);
      case 'new-encounter':
        return IntakeFormPage(onSubmit: _handleAddEncounter);
      case 'encounters':
        return EncountersListPage(
          encounters: _encounters,
          onViewEncounter: _handleViewEncounter,
        );
      case 'encounter-detail':
        if (_selectedEncounter != null) {
          return EncounterDetailPage(
            encounter: _selectedEncounter!,
            onBack: () => _handleNavigate('encounters'),
          );
        }
        return DashboardHomePage(onNavigate: _handleNavigate);
      case 'suggestions':
        return SuggestionsChecklistPage(
          suggestions: _suggestions,
          onUpdateSuggestion: _handleUpdateSuggestion,
        );
      case 'summaries':
        return PatientSummaryPage(encounters: _encounters);
      case 'uploads':
        return FileUploadPage(
          uploadedFiles: _uploadedFiles,
          onFileUpload: _handleAddFile,
          onFileDelete: _handleDeleteFile,
        );
      case 'reminders':
        return RemindersSchedulerPage(
          reminders: _reminders,
          onAddReminder: _handleAddReminder,
          onToggleComplete: _handleToggleReminder,
          onDeleteReminder: _handleDeleteReminder,
        );
      case 'settings':
        return const SettingsPage();
      case 'help':
        return const HelpPage();
      default:
        return DashboardHomePage(onNavigate: _handleNavigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            activeSection: _activeSection == 'encounter-detail'
                ? 'encounters'
                : _activeSection,
            onNavigate: _handleNavigate,
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                TopNavBar(pendingSuggestions: _pendingSuggestions),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

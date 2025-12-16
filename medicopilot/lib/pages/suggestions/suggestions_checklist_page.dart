import 'package:flutter/material.dart';
import '../../components/common/common.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

/// Suggestions checklist page for reviewing AI suggestions
class SuggestionsChecklistPage extends StatefulWidget {
  final List<AISuggestion> suggestions;
  final Function(String, SuggestionStatus) onUpdateSuggestion;

  const SuggestionsChecklistPage({
    super.key,
    required this.suggestions,
    required this.onUpdateSuggestion,
  });

  @override
  State<SuggestionsChecklistPage> createState() => _SuggestionsChecklistPageState();
}

class _SuggestionsChecklistPageState extends State<SuggestionsChecklistPage> {
  String _filter = 'all';

  List<AISuggestion> get _filteredSuggestions {
    if (_filter == 'all') return widget.suggestions;
    return widget.suggestions.where((s) => s.status.name == _filter).toList();
  }

  int get _pendingCount =>
      widget.suggestions.where((s) => s.status == SuggestionStatus.pending).length;
  int get _acceptedCount =>
      widget.suggestions.where((s) => s.status == SuggestionStatus.accepted).length;
  int get _ignoredCount =>
      widget.suggestions.where((s) => s.status == SuggestionStatus.ignored).length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'AI Suggestions & Checklist',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Review and manage clinical suggestions from AI analysis',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // Filter buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterButton(
                label: 'All (${widget.suggestions.length})',
                isActive: _filter == 'all',
                onTap: () => setState(() => _filter = 'all'),
              ),
              _FilterButton(
                label: 'Pending ($_pendingCount)',
                isActive: _filter == 'pending',
                onTap: () => setState(() => _filter = 'pending'),
              ),
              _FilterButton(
                label: 'Accepted ($_acceptedCount)',
                isActive: _filter == 'accepted',
                onTap: () => setState(() => _filter = 'accepted'),
              ),
              _FilterButton(
                label: 'Ignored ($_ignoredCount)',
                isActive: _filter == 'ignored',
                onTap: () => setState(() => _filter = 'ignored'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Suggestions list
          if (_filteredSuggestions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'No suggestions in this category',
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredSuggestions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final suggestion = _filteredSuggestions[index];
                return _SuggestionCard(
                  suggestion: suggestion,
                  onAccept: () => widget.onUpdateSuggestion(
                    suggestion.id,
                    SuggestionStatus.accepted,
                  ),
                  onIgnore: () => widget.onUpdateSuggestion(
                    suggestion.id,
                    SuggestionStatus.ignored,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Filter button widget
class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return isActive
        ? ElevatedButton(
            onPressed: onTap,
            child: Text(label),
          )
        : OutlinedButton(
            onPressed: onTap,
            child: Text(label),
          );
  }
}

/// Suggestion card widget
class _SuggestionCard extends StatelessWidget {
  final AISuggestion suggestion;
  final VoidCallback onAccept;
  final VoidCallback onIgnore;

  const _SuggestionCard({
    required this.suggestion,
    required this.onAccept,
    required this.onIgnore,
  });

  IconData _getCategoryIcon() {
    switch (suggestion.category) {
      case SuggestionCategory.redFlag:
        return Icons.warning_amber;
      case SuggestionCategory.missedVital:
        return Icons.schedule;
      case SuggestionCategory.documentationGap:
        return Icons.description_outlined;
      case SuggestionCategory.recheckValue:
        return Icons.refresh;
      default:
        return Icons.info_outline;
    }
  }

  Color _getCategoryColor() {
    switch (suggestion.category) {
      case SuggestionCategory.redFlag:
        return AppTheme.red;
      case SuggestionCategory.missedVital:
        return AppTheme.amber;
      case SuggestionCategory.documentationGap:
        return AppTheme.blue;
      case SuggestionCategory.recheckValue:
        return AppTheme.purple;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _getCategoryIcon(),
              color: _getCategoryColor(),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusBadge.urgency(suggestion.urgency.name),
                      StatusBadge(
                        label: suggestion.category.displayName,
                        backgroundColor: AppTheme.surfaceVariant,
                        textColor: AppTheme.textSecondary,
                      ),
                      if (suggestion.status != SuggestionStatus.pending)
                        StatusBadge(
                          label: suggestion.status.name,
                          backgroundColor: suggestion.status == SuggestionStatus.accepted
                              ? AppTheme.greenLight
                              : AppTheme.surfaceVariant,
                          textColor: suggestion.status == SuggestionStatus.accepted
                              ? AppTheme.green
                              : AppTheme.textSecondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Suggestion text
                  Text(
                    suggestion.suggestion,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),

                  // Rationale
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rationale:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          suggestion.rationale,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Generated: ${_formatDateTime(suggestion.createdAt)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                      ),
                      if (suggestion.status == SuggestionStatus.pending)
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: onIgnore,
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Ignore'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: onAccept,
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Accept'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.month}/${date.day}/${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fertiflow/services/app_state.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  String _selectedFilter = 'Semua';

  static const List<String> _filterLabels = [
    'Semua',
    'Hama',
    'Irigasi',
    'Pestisida',
    'Peringatan',
  ];

  static const Map<String, List<String>> _filterTypeMap = {
    'Semua': [],
    'Hama': ['pest'],
    'Irigasi': ['irrigation', 'irrigation_done', 'schedule_run', 'schedule_done'],
    'Pestisida': ['spray', 'spray_done'],
    'Peringatan': ['warning', 'soil', 'schedule_fail'],
  };

  static IconData _mapIcon(String iconName) {
    switch (iconName) {
      case 'bug_report':
        return Icons.bug_report_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'check_circle':
        return Icons.check_circle_rounded;
      case 'grass':
        return Icons.grass_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  List<Map<String, dynamic>> _filteredLog(List<Map<String, dynamic>> log) {
    if (_selectedFilter == 'Semua') return log;
    final types = _filterTypeMap[_selectedFilter] ?? [];
    return log.where((a) => types.contains(a['type'])).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Riwayat Aktivitas',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: theme.dividerColor.withValues(alpha: 0.5), height: 1.0),
        ),
      ),
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final allLog = AppState.instance.activityLog;
          final filtered = _filteredLog(allLog);

          return Column(
            children: [
              // ── Filter Chips Row ──────────────────────────────────
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filterLabels.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final label = _filterLabels[index];
                    final isSelected = _selectedFilter == label;

                    return Center(
                      child: ChoiceChip(
                        label: Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF10B981),
                        backgroundColor: theme.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF10B981) : theme.dividerColor.withValues(alpha: 0.8),
                            width: 1,
                          ),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        onSelected: (_) {
                          setState(() => _selectedFilter = label);
                        },
                      ),
                    );
                  },
                ),
              ),

              // ── Timeline List or Empty State ──────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: filtered.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildTimeline(filtered, theme, isDark),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      key: const ValueKey('empty'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada aktivitas',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline List ────────────────────────────────────────────────────────
  Widget _buildTimeline(
    List<Map<String, dynamic>> items,
    ThemeData theme,
    bool isDark,
  ) {
    return ListView.builder(
      key: const ValueKey('timeline'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLast = index == items.length - 1;
        final itemColor = item['color'] is int
            ? Color(item['color'] as int)
            : const Color(0xFF10B981);
        final iconData = _mapIcon((item['icon'] ?? 'check_circle').toString());

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: Timeline Connector + Icon Node ──────────
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    // Icon node
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: itemColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: itemColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(iconData, size: 16, color: itemColor),
                    ),
                    // Bottom connector line
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // ── Right: Activity Card ─────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          (item['title'] ?? 'Aktivitas').toString(),
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Subtitle
                        Text(
                          (item['subtitle'] ?? item['description'] ?? '').toString(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Time
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (item['time'] ?? '').toString(),
                              style: GoogleFonts.shareTechMono(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

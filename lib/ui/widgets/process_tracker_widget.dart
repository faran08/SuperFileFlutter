import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/process_item.dart';
import '../../core/state/superfile_state_manager.dart';

class ProcessTrackerWidget extends StatelessWidget {
  const ProcessTrackerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SuperfileStateManager>();
    final theme = manager.getEffectiveTheme(context);
    final processes = manager.processes;

    if (processes.isEmpty) {
      return Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        color: theme.footerBg,
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 12, color: theme.correct),
            const SizedBox(width: 6),
            Text(
              'PROCESSES: Idle (0 active tasks)',
              style: TextStyle(
                color: theme.footerFg.withValues(alpha: 0.6),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
    }

    return RepaintBoundary(
      // STRICT PERFORMANCE BOUNDARY: Isolates high-frequency progress bar repaints
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.footerBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: theme.footerBorderActive, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync_rounded, size: 16, color: theme.correct),
                const SizedBox(width: 8),
                Text(
                  'PROCESS TRACKER (${processes.length} Active Tasks)',
                  style: TextStyle(
                    color: theme.correct,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: processes.length,
                itemBuilder: (context, index) {
                  final proc = processes[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                proc.title,
                                style: TextStyle(
                                  color: theme.footerFg,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(proc.progress * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: theme.correct,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // RepaintBoundary for smooth progress animation without global rebuilds
                        RepaintBoundary(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: proc.progress,
                              minHeight: 6,
                              backgroundColor: theme.sidebarBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                proc.status == ProcessStatus.failed
                                    ? theme.error
                                    : (proc.status == ProcessStatus.completed
                                        ? theme.correct
                                        : theme.filePanelTopDirectoryIcon),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

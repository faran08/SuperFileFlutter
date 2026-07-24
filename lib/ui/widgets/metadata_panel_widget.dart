import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/state/superfile_state_manager.dart';
import '../../core/theme/superfile_themes.dart';

class MetadataBottomWidget extends StatelessWidget {
  const MetadataBottomWidget({super.key});

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SuperfileStateManager>();
    final theme = manager.getEffectiveTheme(context);
    final activePanel = manager.activePanel;
    final item = activePanel?.currentItem;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: theme.footerBg,
        border: Border(
          top: BorderSide(color: theme.footerBorder, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            item != null
                ? (item.isDirectory ? Icons.folder_rounded : Icons.insert_drive_file_rounded)
                : Icons.folder_open_rounded,
            size: 14,
            color: theme.filePanelTopDirectoryIcon,
          ),
          const SizedBox(width: 6),
          Text(
            item != null ? item.name : (activePanel != null ? 'DIR: ${activePanel.currentPath}' : 'SUPERFILE'),
            style: TextStyle(
              color: theme.filePanelFg,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 16),
          if (item != null) ...[
            _buildPill(theme, 'SIZE', _formatBytes(item.size)),
            const SizedBox(width: 8),
            _buildPill(theme, 'MODE', item.permissions),
            const SizedBox(width: 8),
            _buildPill(theme, 'MODIFIED', DateFormat('MM/dd HH:mm').format(item.modified)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.path,
                style: TextStyle(
                  color: theme.filePanelFg.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else if (activePanel != null) ...[
            _buildPill(theme, 'ITEMS', '${activePanel.filteredItems.length} items'),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                activePanel.currentPath,
                style: TextStyle(
                  color: theme.filePanelFg.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPill(SuperfileTheme theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.sidebarBg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: theme.sidebarBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: theme.filePanelFg.withValues(alpha: 0.6),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.filePanelFg,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

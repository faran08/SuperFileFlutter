import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/superfile_state_manager.dart';
import '../dialogs/shortcuts_help_dialog.dart';

class FooterBarWidget extends StatelessWidget {
  const FooterBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SuperfileStateManager>();
    final theme = manager.getEffectiveTheme(context);
    final isVisual = manager.visualSelectMode;
    final clipboardCount = manager.clipboardPaths.length;
    final isCut = manager.isCutOperation;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.footerBg,
        border: Border(
          top: BorderSide(color: theme.footerBorder, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Vim Mode Pill Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isVisual ? theme.correct : theme.modalConfirmBg,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              isVisual ? 'VISUAL' : 'NORMAL',
              style: TextStyle(
                color: theme.modalConfirmFg,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Clipboard Indicator (Always Visible)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: clipboardCount > 0
                  ? (isCut ? theme.error : theme.hint)
                  : theme.sidebarBg,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: theme.sidebarBorder),
            ),
            child: Text(
              clipboardCount > 0
                  ? '${isCut ? "CUT" : "YANKED"}: $clipboardCount'
                  : 'CLIPBOARD: Empty',
              style: TextStyle(
                color: clipboardCount > 0 ? Colors.black : theme.footerFg.withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Aesthetic Shortcut Badges
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildShortcutBadge(theme, 'j/k', 'Up/Down'),
                  _buildShortcutBadge(theme, 'h/l', 'Nav'),
                  _buildShortcutBadge(theme, 'v', 'Select'),
                  _buildShortcutBadge(theme, 'y/x/p', 'Copy/Cut/Paste'),
                  _buildShortcutBadge(theme, 'Esc', 'Cancel All'),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // All Shortcuts Modal Button
          InkWell(
            onTap: () => ShortcutsHelpDialog.show(context),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.sidebarBg,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: theme.sidebarBorderActive),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_rounded, size: 12, color: theme.correct),
                  const SizedBox(width: 4),
                  Text(
                    '? Shortcuts',
                    style: TextStyle(
                      color: theme.filePanelFg,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Theme Name Badge
          Text(
            manager.currentTheme.name,
            style: TextStyle(
              color: theme.footerBorderActive,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutBadge(dynamic theme, String key, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
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
            '$key: ',
            style: TextStyle(
              color: theme.correct,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: theme.filePanelFg.withValues(alpha: 0.7),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/superfile_state_manager.dart';

class ShortcutsHelpDialog extends StatelessWidget {
  const ShortcutsHelpDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ShortcutsHelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SuperfileStateManager>();
    final theme = manager.getEffectiveTheme(context);

    return Dialog(
      backgroundColor: theme.modalBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.modalBorderActive, width: 1.5),
      ),
      child: Container(
        width: 640,
        height: 480,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.keyboard_rounded, color: theme.correct, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'SUPERFILE KEYBOARD SHORTCUTS',
                      style: TextStyle(
                        color: theme.modalFg,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.1,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: theme.modalFg.withValues(alpha: 0.6),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: theme.footerBorder, height: 1),
            const SizedBox(height: 16),

            // Category Grid
            Expanded(
              child: ListView(
                children: [
                  _buildCategoryCard(
                    theme,
                    title: '🚀 NAVIGATION',
                    icon: Icons.navigation_rounded,
                    shortcuts: [
                      _ShortcutItem('j / Down', 'Move cursor down'),
                      _ShortcutItem('k / Up', 'Move cursor up'),
                      _ShortcutItem('l / Enter / Right', 'Open directory / File'),
                      _ShortcutItem('h / Backspace / -', 'Go to parent directory'),
                      _ShortcutItem('Double Click', 'Open folder or file in default app'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryCard(
                    theme,
                    title: '📁 FILE OPERATIONS',
                    icon: Icons.folder_zip_rounded,
                    shortcuts: [
                      _ShortcutItem('y / Copy', 'Yank / Copy selected file(s)'),
                      _ShortcutItem('x / Cut', 'Cut selected file(s)'),
                      _ShortcutItem('p / Paste', 'Paste clipboard items into current folder'),
                      _ShortcutItem('a / New', 'Create new File or Folder'),
                      _ShortcutItem('r / Rename', 'Rename current item'),
                      _ShortcutItem('d / Delete', 'Delete selected file(s)'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryCard(
                    theme,
                    title: '👁️ SELECTION & MODES',
                    icon: Icons.visibility_rounded,
                    shortcuts: [
                      _ShortcutItem('v', 'Toggle Visual Selection mode'),
                      _ShortcutItem('Esc', 'Cancel active action / Clear selection & clipboard'),
                      _ShortcutItem('u', 'Unselect all items in current panel'),
                      _ShortcutItem('.', 'Toggle hidden files (.dotfiles)'),
                      _ShortcutItem('/', 'Search filter in current folder'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryCard(
                    theme,
                    title: '📑 SPLIT PANELS & TABS',
                    icon: Icons.view_column_rounded,
                    shortcuts: [
                      _ShortcutItem('n', 'Open new split view tab (Max 3)'),
                      _ShortcutItem('q / Tab Close', 'Close current tab'),
                      _ShortcutItem('Tab / Shift+Tab', 'Cycle focus between split panels'),
                      _ShortcutItem('Ctrl + S', 'Toggle left sidebar'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryCard(
                    theme,
                    title: '⌨️ COMMAND BAR (:)',
                    icon: Icons.terminal_rounded,
                    shortcuts: [
                      _ShortcutItem(':', 'Open command bar modal'),
                      _ShortcutItem(':cd <path>', 'Navigate to directory path'),
                      _ShortcutItem(':mkdir <name>', 'Create new directory'),
                      _ShortcutItem(':touch <name>', 'Create new empty file'),
                      _ShortcutItem(':theme <name>', 'Switch theme (mocha, latte, nord, tokyonight, system)'),
                      _ShortcutItem(':compress <name.zip>', 'Compress selected items into zip archive'),
                      _ShortcutItem(':extract', 'Extract selected zip archive'),
                      _ShortcutItem(':select all', 'Select all items in active directory'),
                      _ShortcutItem(':select clear', 'Unselect all items'),
                      _ShortcutItem(':hidden', 'Toggle dotfiles / hidden files'),
                      _ShortcutItem(':quit', 'Close current active panel'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryCard(
                    theme,
                    title: '🎨 THEMES & PREFERENCES',
                    icon: Icons.palette_rounded,
                    shortcuts: [
                      _ShortcutItem('System (Auto)', 'Automatically matches macOS Light/Dark mode'),
                      _ShortcutItem('Catppuccin Mocha', 'Classic Dark TUI palette'),
                      _ShortcutItem('Catppuccin Latte', 'Clean Light palette'),
                      _ShortcutItem('Nord & Tokyo Night', 'Modern dark terminal themes'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Footer Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.modalConfirmBg,
                  foregroundColor: theme.modalConfirmFg,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    dynamic theme, {
    required String title,
    required IconData icon,
    required List<_ShortcutItem> shortcuts,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.sidebarBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.sidebarBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: theme.correct),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: theme.correct,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...shortcuts.map((sc) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.modalConfirmBg.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: theme.modalConfirmBg.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        sc.key,
                        style: TextStyle(
                          color: theme.filePanelItemSelectedFg,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sc.description,
                        style: TextStyle(
                          color: theme.filePanelFg.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ShortcutItem {
  final String key;
  final String description;
  const _ShortcutItem(this.key, this.description);
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/superfile_state_manager.dart';
import '../../core/theme/superfile_themes.dart';
import '../dialogs/input_dialog.dart';
import '../dialogs/shortcuts_help_dialog.dart';

class CommandBarDialog extends StatefulWidget {
  const CommandBarDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CommandBarDialog(),
    );
  }

  @override
  State<CommandBarDialog> createState() => _CommandBarDialogState();
}

class _CommandBarDialogState extends State<CommandBarDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _executeCommand(String input) {
    final raw = input.trim();
    if (raw.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final cmd = raw.startsWith(':') ? raw.substring(1).trim() : raw;
    final manager = context.read<SuperfileStateManager>();
    final ap = manager.activePanel;

    setState(() => _errorMessage = null);

    if (cmd.startsWith('cd')) {
      final path = cmd.substring(2).trim();
      if (path.isEmpty) {
        setState(() => _errorMessage = '❌ Invalid Command: ":cd" requires a directory path (e.g., :cd /Users/name)');
        return;
      }
      if (ap != null) manager.navigateTo(ap.panelId, path);
    } else if (cmd.startsWith('mkdir')) {
      final name = cmd.substring(5).trim();
      if (name.isEmpty) {
        setState(() => _errorMessage = '❌ Invalid Command: ":mkdir" requires a folder name (e.g., :mkdir NewFolder)');
        return;
      }
      manager.createNewItem(name, isDirectory: true);
    } else if (cmd.startsWith('touch')) {
      final name = cmd.substring(5).trim();
      if (name.isEmpty) {
        setState(() => _errorMessage = '❌ Invalid Command: ":touch" requires a file name (e.g., :touch notes.txt)');
        return;
      }
      manager.createNewItem(name, isDirectory: false);
    } else if (cmd.startsWith('theme')) {
      final query = cmd.substring(5).trim().toLowerCase();
      if (query.isEmpty) {
        setState(() => _errorMessage = '❌ Invalid Command: ":theme" requires a theme name (e.g., :theme nord, :theme mocha, :theme latte)');
        return;
      }
      final matched = SuperfileTheme.allThemes.firstWhere(
        (t) => t.name.toLowerCase().contains(query),
        orElse: () => manager.currentTheme,
      );
      manager.setTheme(matched);
    } else if (cmd == 'select all' || cmd == 'all') {
      manager.selectAllInActivePanel();
    } else if (cmd == 'select clear' || cmd == 'clear' || cmd == 'unselect') {
      if (ap != null) manager.clearSelection(ap.panelId);
    } else if (cmd == 'hidden' || cmd == 'dotfiles') {
      manager.toggleHiddenFiles();
    } else if (cmd.startsWith('compress')) {
      final zipName = cmd.substring(8).trim();
      if (zipName.isNotEmpty) {
        manager.compressSelectedToZip(zipName);
      } else {
        InputDialog.show(
          context,
          title: 'COMPRESS TO ZIP',
          initialValue: 'archive.zip',
          confirmLabel: 'Compress',
          onConfirm: (name) => manager.compressSelectedToZip(name),
        );
      }
    } else if (cmd == 'extract') {
      manager.extractSelectedZip();
    } else if (cmd == 'help' || cmd == '?') {
      ShortcutsHelpDialog.show(context);
    } else if (cmd == 'quit' || cmd == 'q') {
      manager.closeActivePanel();
    } else {
      setState(() {
        _errorMessage = '❌ Unknown Command ":$cmd". Valid commands: :cd <path>, :mkdir <name>, :touch <file>, :theme <name>, :compress, :extract, :select all, :hidden, :help, :quit';
      });
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SuperfileStateManager>();
    final theme = manager.getEffectiveTheme(context);

    return Dialog(
      backgroundColor: theme.modalBg,
      alignment: Alignment.bottomCenter,
      insetPadding: const EdgeInsets.only(bottom: 40, left: 60, right: 60),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _errorMessage != null ? theme.error : theme.correct,
          width: 1.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Command Bar Header & Input
            Row(
              children: [
                Text(
                  ':',
                  style: TextStyle(
                    color: theme.correct,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: TextStyle(
                      color: theme.modalFg,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter command (e.g. cd /Users, mkdir Projects, theme nord, compress archive.zip)',
                      hintStyle: TextStyle(
                        color: theme.modalFg.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: _executeCommand,
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: theme.modalFg.withValues(alpha: 0.6),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            // Error Banner if invalid command entered
            if (_errorMessage != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: theme.error.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: theme.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),
            Divider(color: theme.footerBorder, height: 1),
            const SizedBox(height: 8),

            // Comprehensive Guide Strip
            Row(
              children: [
                Icon(Icons.help_outline_rounded, size: 12, color: theme.correct),
                const SizedBox(width: 6),
                Text(
                  'COMMAND GUIDE:',
                  style: TextStyle(
                    color: theme.correct,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildGuideChip(theme, ':cd <path>', 'Jump to folder'),
                        _buildGuideChip(theme, ':mkdir <name>', 'Create folder'),
                        _buildGuideChip(theme, ':touch <name>', 'Create file'),
                        _buildGuideChip(theme, ':theme <name>', 'Change theme'),
                        _buildGuideChip(theme, ':compress <zip>', 'Zip files'),
                        _buildGuideChip(theme, ':extract', 'Unzip selected'),
                        _buildGuideChip(theme, ':select all', 'Select all items'),
                        _buildGuideChip(theme, ':hidden', 'Toggle dotfiles'),
                        _buildGuideChip(theme, ':help', 'Open help modal'),
                        _buildGuideChip(theme, ':quit', 'Close tab'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideChip(dynamic theme, String command, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
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
            '$command ',
            style: TextStyle(
              color: theme.filePanelItemSelectedFg,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            '($label)',
            style: TextStyle(
              color: theme.filePanelFg.withValues(alpha: 0.6),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

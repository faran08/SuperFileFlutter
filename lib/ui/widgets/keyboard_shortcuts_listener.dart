import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/state/superfile_state_manager.dart';
import '../dialogs/command_bar_dialog.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/input_dialog.dart';
import '../dialogs/shortcuts_help_dialog.dart';

class KeyboardShortcutsListener extends StatefulWidget {
  final Widget child;

  const KeyboardShortcutsListener({super.key, required this.child});

  @override
  State<KeyboardShortcutsListener> createState() => _KeyboardShortcutsListenerState();
}

class _KeyboardShortcutsListenerState extends State<KeyboardShortcutsListener> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event, SuperfileStateManager manager) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    final isControlPressed = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    final activePanel = manager.activePanel;
    final panelId = activePanel?.panelId ?? 'panel_0';

    // 1. Global Navigation Shortcuts with Control
    if (isControlPressed) {
      if (key == LogicalKeyboardKey.keyS) {
        manager.toggleSidebar();
        return;
      } else if (key == LogicalKeyboardKey.keyD) {
        manager.toggleMetadataPanel();
        return;
      } else if (key == LogicalKeyboardKey.keyN) {
        manager.createNewPanel();
        return;
      } else if (key == LogicalKeyboardKey.keyW) {
        manager.closeActivePanel();
        return;
      }
    }

    // 2. Tab Navigation
    if (key == LogicalKeyboardKey.tab) {
      if (isShiftPressed) {
        manager.cycleFocusPrevious();
      } else {
        manager.cycleFocus();
      }
      return;
    }

    // 3. Vim Navigation (Normal & Visual Modes)
    if (key == LogicalKeyboardKey.keyK || key == LogicalKeyboardKey.arrowUp) {
      manager.moveCursorUp();
      return;
    } else if (key == LogicalKeyboardKey.keyJ || key == LogicalKeyboardKey.arrowDown) {
      manager.moveCursorDown();
      return;
    } else if (key == LogicalKeyboardKey.keyH || key == LogicalKeyboardKey.arrowLeft) {
      manager.navigateParent(panelId);
      return;
    } else if (key == LogicalKeyboardKey.keyL || key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.enter) {
      manager.openCurrentSelectedItem(panelId);
      return;
    } else if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.backspace) {
      manager.navigateParent(panelId);
      return;
    }

    // 4. File Operation & Selection Hotkeys
    if (key == LogicalKeyboardKey.colon || key == LogicalKeyboardKey.semicolon && HardwareKeyboard.instance.isShiftPressed) {
      CommandBarDialog.show(context);
      return;
    } else if (key == LogicalKeyboardKey.slash && HardwareKeyboard.instance.isShiftPressed) { // ? key
      ShortcutsHelpDialog.show(context);
      return;
    } else if (key == LogicalKeyboardKey.keyA && (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed)) {
      manager.selectAllInActivePanel();
      return;
    } else if (key == LogicalKeyboardKey.escape) {
      manager.cancelAllActions();
      return;
    } else if (key == LogicalKeyboardKey.keyU) {
      manager.clearSelection(panelId);
      return;
    } else if (key == LogicalKeyboardKey.keyV) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        manager.selectAllInActivePanel();
      } else {
        manager.toggleVisualSelectMode();
      }
      return;
    } else if (key == LogicalKeyboardKey.keyN) {
      manager.createNewPanel();
      return;
    } else if (key == LogicalKeyboardKey.keyQ) {
      manager.closeActivePanel();
      return;
    } else if (key == LogicalKeyboardKey.period) {
      manager.toggleHiddenFiles();
      return;
    } else if (key == LogicalKeyboardKey.keyF) {
      manager.toggleMetadataPanel();
      return;
    } else if (key == LogicalKeyboardKey.keyO) {
      manager.cycleSortMode();
      return;
    } else if (key == LogicalKeyboardKey.keyY) {
      manager.copySelected();
      return;
    } else if (key == LogicalKeyboardKey.keyX) {
      manager.cutSelected();
      return;
    } else if (key == LogicalKeyboardKey.keyP) {
      manager.pasteClipboard();
      return;
    } else if (key == LogicalKeyboardKey.keyA) {
      _showCreateDialog(context, manager);
      return;
    } else if (key == LogicalKeyboardKey.keyR) {
      _showRenameDialog(context, manager);
      return;
    } else if (key == LogicalKeyboardKey.keyD || key == LogicalKeyboardKey.delete) {
      _showDeleteConfirmDialog(context, manager);
      return;
    } else if (key == LogicalKeyboardKey.slash) {
      _showSearchDialog(context, manager);
      return;
    }
  }

  void _showCreateDialog(BuildContext context, SuperfileStateManager manager) {
    InputDialog.show(
      context,
      title: 'CREATE NEW ITEM (End with / for directory)',
      confirmLabel: 'Create',
      onConfirm: (input) {
        final isDir = input.endsWith('/');
        final name = isDir ? input.substring(0, input.length - 1) : input;
        manager.createNewItem(name, isDirectory: isDir);
      },
    );
  }

  void _showRenameDialog(BuildContext context, SuperfileStateManager manager) {
    final currentItem = manager.activePanel?.currentItem;
    if (currentItem == null) return;

    InputDialog.show(
      context,
      title: 'RENAME ITEM',
      initialValue: currentItem.name,
      confirmLabel: 'Rename',
      onConfirm: (newName) {
        manager.renameSelectedItem(newName);
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, SuperfileStateManager manager) {
    final ap = manager.activePanel;
    if (ap == null) return;
    final selected = manager.getSelectedPaths(ap.panelId);
    final count = selected.isNotEmpty ? selected.length : (ap.currentItem != null ? 1 : 0);
    if (count == 0) return;

    ConfirmDialog.show(
      context,
      title: 'DELETE CONFIRMATION',
      message: 'Are you sure you want to permanently delete $count item(s)?',
      confirmLabel: 'Delete',
      onConfirm: () => manager.deleteSelected(permanent: true),
    );
  }

  void _showSearchDialog(BuildContext context, SuperfileStateManager manager) {
    InputDialog.show(
      context,
      title: 'FILTER DIRECTORY',
      confirmLabel: 'Apply Filter',
      onConfirm: (query) {
        manager.setSearchFilter(query);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.read<SuperfileStateManager>();

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) => _handleKeyEvent(event, manager),
      child: widget.child,
    );
  }
}

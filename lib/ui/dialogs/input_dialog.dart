import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/superfile_state_manager.dart';

class InputDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final String confirmLabel;
  final Function(String input) onConfirm;

  const InputDialog({
    super.key,
    required this.title,
    this.initialValue = '',
    this.confirmLabel = 'OK',
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    String initialValue = '',
    String confirmLabel = 'OK',
    required Function(String input) onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => InputDialog(
        title: title,
        initialValue: initialValue,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<SuperfileStateManager>().currentTheme;

    return Dialog(
      backgroundColor: theme.modalBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: theme.modalBorderActive, width: 1.5),
      ),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: theme.modalFg,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(
                color: theme.filePanelFg,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.sidebarBg,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.modalBorderActive),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.filePanelBorder),
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  widget.onConfirm(value.trim());
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: theme.modalCancelBg,
                    foregroundColor: theme.modalCancelFg,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(fontFamily: 'monospace')),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.modalConfirmBg,
                    foregroundColor: theme.modalConfirmFg,
                  ),
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      widget.onConfirm(text);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(widget.confirmLabel, style: const TextStyle(fontFamily: 'monospace')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

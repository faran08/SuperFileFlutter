import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/superfile_state_manager.dart';

class HeaderBarWidget extends StatelessWidget {
  const HeaderBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SuperfileStateManager>();
    final theme = manager.getEffectiveTheme(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.fullScreenBg,
      child: Row(
        children: [
          // Logo / App Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: theme.gradientColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'SPF',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Active Panel Tabs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(manager.panels.length, (index) {
                  final isFocused = manager.activePanelIndex == index;

                  return InkWell(
                    onTap: () => manager.setFocus('panel_$index'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFocused ? theme.filePanelItemSelectedBg : theme.sidebarBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isFocused ? theme.filePanelBorderActive : theme.filePanelBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tab_rounded,
                            size: 14,
                            color: isFocused ? theme.filePanelItemSelectedFg : theme.filePanelFg,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Panel ${index + 1}',
                            style: TextStyle(
                              color: isFocused ? theme.filePanelItemSelectedFg : theme.filePanelFg,
                              fontSize: 12,
                              fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (manager.panels.length > 1) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => manager.closePanelAtIndex(index),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: isFocused ? theme.filePanelItemSelectedFg : theme.filePanelFg.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Action buttons: New Panel (Max 3), Toggle Sidebar, Toggle Metadata
          IconButton(
            icon: const Icon(Icons.view_column_rounded, size: 18),
            color: manager.panels.length < 3 ? theme.filePanelFg : theme.filePanelFg.withValues(alpha: 0.3),
            tooltip: manager.panels.length < 3 ? 'New Split Panel (n)' : 'Max 3 Panels Reached',
            onPressed: manager.panels.length < 3 ? () => manager.createNewPanel() : null,
          ),
          IconButton(
            icon: const Icon(Icons.view_sidebar_rounded, size: 18),
            color: theme.filePanelFg,
            tooltip: 'Toggle Sidebar (Ctrl+S)',
            onPressed: () => manager.toggleSidebar(),
          ),
          IconButton(
            icon: const Icon(Icons.dock_rounded, size: 18),
            color: theme.filePanelFg,
            tooltip: 'Toggle Metadata Panel (f)',
            onPressed: () => manager.toggleMetadataPanel(),
          ),
        ],
      ),
    );
  }
}

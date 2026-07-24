import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../core/state/superfile_state_manager.dart';
import '../../core/theme/superfile_themes.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  List<_SidebarItem> _getFavorites() {
    final home = Platform.environment['HOME'] ?? Directory.current.path;
    return [
      _SidebarItem(name: 'Home', path: home, icon: Icons.home_rounded),
      _SidebarItem(name: 'Desktop', path: p.join(home, 'Desktop'), icon: Icons.desktop_mac_rounded),
      _SidebarItem(name: 'Downloads', path: p.join(home, 'Downloads'), icon: Icons.download_rounded),
      _SidebarItem(name: 'Documents', path: p.join(home, 'Documents'), icon: Icons.description_rounded),
      _SidebarItem(name: 'Pictures', path: p.join(home, 'Pictures'), icon: Icons.image_rounded),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SuperfileStateManager>();
    final theme = manager.getEffectiveTheme(context);
    final isFocused = manager.currentFocus == 'sidebar';
    final activePanel = manager.activePanel;

    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: theme.sidebarBg,
        border: Border(
          right: BorderSide(
            color: isFocused ? theme.sidebarBorderActive : theme.sidebarBorder,
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.sidebarBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_special_rounded, color: theme.sidebarTitle, size: 16),
                const SizedBox(width: 8),
                Text(
                  'SUPERFILE',
                  style: TextStyle(
                    color: theme.sidebarTitle,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pinned Locations
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 10, bottom: 4),
                    child: Text(
                      'PINNED PLACES',
                      style: TextStyle(
                        color: theme.sidebarFg.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),

          ..._getFavorites().map((fav) {
            final isCurrent = activePanel?.currentPath == fav.path;
            return InkWell(
              onTap: () {
                if (activePanel != null) {
                  manager.navigateTo(activePanel.panelId, fav.path);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isCurrent ? theme.sidebarItemSelectedBg : Colors.transparent,
                child: Row(
                  children: [
                    Icon(
                      fav.icon,
                      size: 16,
                      color: isCurrent ? theme.sidebarItemSelectedFg : theme.sidebarFg,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fav.name,
                        style: TextStyle(
                          color: isCurrent ? theme.sidebarItemSelectedFg : theme.sidebarFg,
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const Divider(height: 24, thickness: 1),

          // Themes Menu
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4, bottom: 6),
            child: Text(
              'COLOR THEMES',
              style: TextStyle(
                color: theme.sidebarFg.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                fontFamily: 'monospace',
              ),
            ),
          ),

          ...SuperfileTheme.allThemes.map((th) {
            final isSelected = th.name == theme.name;
            return InkWell(
              onTap: () => manager.setTheme(th),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: th.filePanelBorderActive,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        th.name,
                        style: TextStyle(
                          color: isSelected ? theme.sidebarItemSelectedFg : theme.sidebarFg,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    ),
  ),

          // Shortcut hint at bottom of sidebar
          Container(
            padding: const EdgeInsets.all(10),
            color: theme.sidebarBg,
            child: Text(
              'Ctrl+S: Sidebar\nTab: Next Panel',
              style: TextStyle(
                color: theme.sidebarFg.withValues(alpha: 0.5),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem {
  final String name;
  final String path;
  final IconData icon;
  const _SidebarItem({required this.name, required this.path, required this.icon});
}

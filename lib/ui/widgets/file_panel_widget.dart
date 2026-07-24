import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../core/models/file_item.dart';
import '../../core/models/panel_state.dart';
import '../../core/state/superfile_state_manager.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/input_dialog.dart';

class FilePanelWidget extends StatefulWidget {
  final PanelState panel;
  final bool isFocused;

  const FilePanelWidget({
    super.key,
    required this.panel,
    required this.isFocused,
  });

  @override
  State<FilePanelWidget> createState() => _FilePanelWidgetState();
}

class _FilePanelWidgetState extends State<FilePanelWidget> {
  final ScrollController _scrollController = ScrollController();
  static const double _rowItemExtent = 28.0;

  @override
  void didUpdateWidget(covariant FilePanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.panel.cursorIndex != oldWidget.panel.cursorIndex) {
      _scrollToCursor();
    }
  }

  void _scrollToCursor() {
    if (!_scrollController.hasClients) return;
    final targetOffset = widget.panel.cursorIndex * _rowItemExtent;
    final viewportHeight = _scrollController.position.viewportDimension;
    final currentScroll = _scrollController.offset;

    if (targetOffset < currentScroll) {
      _scrollController.jumpTo(targetOffset);
    } else if (targetOffset + _rowItemExtent > currentScroll + viewportHeight) {
      _scrollController.jumpTo(targetOffset + _rowItemExtent - viewportHeight);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatSize(int bytes, bool isDir) {
    if (isDir) return '<DIR>';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _getFileIcon(FileItem item) {
    if (item.isDirectory) return Icons.folder_rounded;
    switch (item.extension) {
      case 'dart':
      case 'go':
      case 'py':
      case 'js':
      case 'ts':
      case 'html':
      case 'css':
      case 'json':
      case 'yaml':
      case 'toml':
        return Icons.code_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'svg':
        return Icons.image_rounded;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audiotrack_rounded;
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
        return Icons.video_library_rounded;
      case 'zip':
      case 'tar':
      case 'gz':
      case '7z':
        return Icons.archive_rounded;
      case 'docx':
      case 'doc':
        return Icons.description_rounded;
      case 'pptx':
      case 'ppt':
        return Icons.slideshow_rounded;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'txt':
      case 'md':
        return Icons.article_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  // Clickable path breadcrumbs widget
  Widget _buildBreadcrumbs(BuildContext context, SuperfileStateManager manager) {
    final theme = manager.currentTheme;
    final parts = p.split(widget.panel.currentPath);

    List<Widget> breadcrumbWidgets = [];
    String accumulatedPath = '';

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (i == 0 && (part == '/' || part.endsWith(':\\'))) {
        accumulatedPath = part;
      } else {
        accumulatedPath = p.join(accumulatedPath, part);
      }

      final targetPath = accumulatedPath;
      final isLast = i == parts.length - 1;

      breadcrumbWidgets.add(
        InkWell(
          onTap: () => manager.navigateTo(widget.panel.panelId, targetPath),
          child: Text(
            part == '/' ? ' / ' : part,
            style: TextStyle(
              color: isLast ? theme.filePanelTopPath : theme.filePanelFg.withValues(alpha: 0.7),
              fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );

      if (!isLast && part != '/') {
        breadcrumbWidgets.add(
          Text(
            ' / ',
            style: TextStyle(
              color: theme.filePanelBorder,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        );
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: breadcrumbWidgets),
    );
  }

  void _showContextMenu(BuildContext context, Offset position, FileItem? item, SuperfileStateManager manager) {
    final theme = manager.currentTheme;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      color: theme.modalBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: theme.modalBorderActive, width: 1),
      ),
      items: <PopupMenuEntry<dynamic>>[
        if (item != null && item.isDirectory)
          PopupMenuItem(
            onTap: () => manager.openCurrentSelectedItem(widget.panel.panelId),
            child: Row(
              children: [
                Icon(Icons.folder_open_rounded, size: 16, color: theme.modalFg),
                const SizedBox(width: 8),
                Text('Open Directory', style: TextStyle(color: theme.modalFg, fontFamily: 'monospace')),
              ],
            ),
          ),
        PopupMenuItem(
          onTap: () => manager.copySelected(),
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 16, color: theme.modalFg),
              const SizedBox(width: 8),
              Text('Copy (Yank)', style: TextStyle(color: theme.modalFg, fontFamily: 'monospace')),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => manager.cutSelected(),
          child: Row(
            children: [
              Icon(Icons.cut_rounded, size: 16, color: theme.modalFg),
              const SizedBox(width: 8),
              Text('Cut', style: TextStyle(color: theme.modalFg, fontFamily: 'monospace')),
            ],
          ),
        ),
        if (manager.clipboardPaths.isNotEmpty)
          PopupMenuItem(
            onTap: () => manager.pasteClipboard(),
            child: Row(
              children: [
                Icon(Icons.paste_rounded, size: 16, color: theme.modalFg),
                const SizedBox(width: 8),
                Text('Paste (${manager.clipboardPaths.length} items)', style: TextStyle(color: theme.modalFg, fontFamily: 'monospace')),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () {
            InputDialog.show(
              context,
              title: 'CREATE NEW ITEM (end with / for dir)',
              confirmLabel: 'Create',
              onConfirm: (input) {
                final isDir = input.endsWith('/');
                final name = isDir ? input.substring(0, input.length - 1) : input;
                manager.createNewItem(name, isDirectory: isDir);
              },
            );
          },
          child: Row(
            children: [
              Icon(Icons.add_rounded, size: 16, color: theme.modalFg),
              const SizedBox(width: 8),
              Text('New File / Folder', style: TextStyle(color: theme.modalFg, fontFamily: 'monospace')),
            ],
          ),
        ),
        if (item != null) ...[
          PopupMenuItem(
            onTap: () {
              InputDialog.show(
                context,
                title: 'RENAME ITEM',
                initialValue: item.name,
                confirmLabel: 'Rename',
                onConfirm: (newName) => manager.renameSelectedItem(newName),
              );
            },
            child: Row(
              children: [
                Icon(Icons.edit_rounded, size: 16, color: theme.modalFg),
                const SizedBox(width: 8),
                Text('Rename', style: TextStyle(color: theme.modalFg, fontFamily: 'monospace')),
              ],
            ),
          ),
          PopupMenuItem(
            onTap: () {
              ConfirmDialog.show(
                context,
                title: 'DELETE CONFIRMATION',
                message: 'Delete ${item.name}?',
                confirmLabel: 'Delete',
                onConfirm: () => manager.deleteSelected(permanent: true),
              );
            },
            child: Row(
              children: [
                Icon(Icons.delete_forever_rounded, size: 16, color: theme.error),
                const SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: theme.error, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            onTap: () {
              InputDialog.show(
                context,
                title: 'COMPRESS TO ZIP',
                initialValue: '${item.name}.zip',
                confirmLabel: 'Compress',
                onConfirm: (zipName) => manager.compressSelectedToZip(zipName),
              );
            },
            child: Row(
              children: [
                Icon(Icons.archive_rounded, size: 16, color: theme.modalFg),
                const SizedBox(width: 8),
                Text('Compress to ZIP', style: TextStyle(color: theme.modalFg, fontFamily: 'monospace')),
              ],
            ),
          ),
          if (item.extension.toLowerCase() == 'zip')
            PopupMenuItem(
              onTap: () => manager.extractSelectedZip(),
              child: Row(
                children: [
                  Icon(Icons.unarchive_rounded, size: 16, color: theme.correct),
                  const SizedBox(width: 8),
                  Text('Extract ZIP Archive', style: TextStyle(color: theme.correct, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SuperfileStateManager>();
    final theme = manager.getEffectiveTheme(context);
    final filteredItems = widget.panel.filteredItems;
    final selectedPaths = manager.getSelectedPaths(widget.panel.panelId);
    final clipboardPaths = manager.clipboardPaths;

    final borderColor = widget.isFocused
        ? theme.filePanelBorderActive
        : theme.filePanelBorder;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.filePanelBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: widget.isFocused ? 1.8 : 1.0),
      ),
      child: Column(
        children: [
          // Panel Top Header (Clickable Breadcrumbs & Sort Indicators)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.filePanelBg,
              border: Border(
                bottom: BorderSide(color: theme.filePanelBorder, width: 1.0),
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => manager.navigateParent(widget.panel.panelId),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: theme.filePanelTopDirectoryIcon,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildBreadcrumbs(context, manager)),
                const SizedBox(width: 8),
                Text(
                  '[${filteredItems.length}]',
                  style: TextStyle(
                    color: theme.filePanelFg.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Search bar (if active)
          if (widget.panel.searchFilter.isNotEmpty || widget.panel.isSearching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: theme.sidebarItemSelectedBg,
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 16, color: theme.hint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filter: ${widget.panel.searchFilter}',
                      style: TextStyle(
                        color: theme.hint,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => manager.setSearchFilter(''),
                    child: Icon(Icons.close_rounded, size: 14, color: theme.hint),
                  ),
                ],
              ),
            ),

          // Clickable Column Header Bar (Mouse Sorting)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: theme.sidebarBg,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (widget.panel.sortMode == FileSortMode.name) {
                        manager.toggleReverseSort();
                      } else {
                        manager.cycleSortMode();
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          'NAME',
                          style: TextStyle(
                            color: widget.panel.sortMode == FileSortMode.name ? theme.filePanelTopPath : theme.filePanelFg.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (widget.panel.sortMode == FileSortMode.name)
                          Icon(widget.panel.isReverseSort ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 12, color: theme.filePanelTopPath),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: InkWell(
                    onTap: () {
                      if (widget.panel.sortMode == FileSortMode.size) {
                        manager.toggleReverseSort();
                      } else {
                        manager.cycleSortMode();
                      }
                    },
                    child: Text(
                      'SIZE',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: widget.panel.sortMode == FileSortMode.size ? theme.filePanelTopPath : theme.filePanelFg.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: InkWell(
                    onTap: () {
                      if (widget.panel.sortMode == FileSortMode.date) {
                        manager.toggleReverseSort();
                      } else {
                        manager.cycleSortMode();
                      }
                    },
                    child: Text(
                      'MODIFIED',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: widget.panel.sortMode == FileSortMode.date ? theme.filePanelTopPath : theme.filePanelFg.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ListView.builder with strictly enforced itemExtent
          Expanded(
            child: filteredItems.isEmpty
                ? GestureDetector(
                    onSecondaryTapUp: (details) => _showContextMenu(context, details.globalPosition, null, manager),
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Text(
                          'Empty Directory (Right-click for menu)',
                          style: TextStyle(
                            color: theme.filePanelFg.withValues(alpha: 0.4),
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemExtent: _rowItemExtent,
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isCursor = widget.isFocused && widget.panel.cursorIndex == index;
                      final isSelected = selectedPaths.contains(item.path);
                      final isClipboard = clipboardPaths.contains(item.path);

                      Color bg = Colors.transparent;
                      if (isCursor) {
                        bg = theme.filePanelItemSelectedBg;
                      } else if (isSelected) {
                        bg = theme.filePanelItemSelectedBg.withValues(alpha: 0.5);
                      }

                      Color fg = item.isDirectory
                          ? theme.filePanelTopDirectoryIcon
                          : theme.filePanelFg;

                      if (isCursor) {
                        fg = theme.filePanelItemSelectedFg;
                      }

                      return GestureDetector(
                        onSecondaryTapUp: (details) {
                          manager.setFocus(widget.panel.panelId);
                          manager.setCursorIndex(widget.panel.panelId, index);
                          _showContextMenu(context, details.globalPosition, item, manager);
                        },
                        child: Listener(
                          onPointerDown: (_) {
                            manager.setFocus(widget.panel.panelId);
                            manager.setCursorIndex(widget.panel.panelId, index);
                          },
                          child: InkWell(
                            onDoubleTap: () => manager.openCurrentSelectedItem(widget.panel.panelId),
                            child: Container(
                            height: _rowItemExtent,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            color: bg,
                            child: Row(
                              children: [
                                // Cursor or Visual Selection Box
                                SizedBox(
                                  width: 20,
                                  child: isCursor
                                      ? Text(
                                          '❯',
                                          style: TextStyle(
                                            color: theme.cursor,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace',
                                          ),
                                        )
                                      : (isSelected
                                          ? Icon(Icons.check_box_rounded, size: 14, color: theme.correct)
                                          : null),
                                ),

                                // File Icon
                                Icon(
                                  _getFileIcon(item),
                                  size: 16,
                                  color: fg,
                                ),
                                const SizedBox(width: 8),

                                // File Name
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      color: fg,
                                      fontSize: 11,
                                      fontWeight: item.isDirectory ? FontWeight.bold : FontWeight.normal,
                                      fontStyle: isClipboard ? FontStyle.italic : FontStyle.normal,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // Size
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    _formatSize(item.size, item.isDirectory),
                                    style: TextStyle(
                                      color: fg.withValues(alpha: 0.7),
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Date Modified
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    DateFormat('MM/dd HH:mm').format(item.modified),
                                    style: TextStyle(
                                      color: fg.withValues(alpha: 0.5),
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../isolates/file_isolates.dart';
import '../models/file_item.dart';
import '../models/panel_state.dart';
import '../models/process_item.dart';
import '../theme/superfile_themes.dart';

class SuperfileStateManager extends ChangeNotifier {
  SuperfileTheme _currentTheme = SuperfileTheme.catppuccinMocha;
  String _currentFocus = 'panel_0';
  int _activePanelIndex = 0;
  bool _showMetadataPanel = true;
  bool _showSidebar = true;
  bool _visualSelectMode = false;

  final List<PanelState> _panels = [];
  final Map<String, Set<String>> _selectedPathsPerPanel = {};

  List<String> _clipboardPaths = [];
  bool _isCutOperation = false;

  final List<ProcessItem> _processes = [];

  SuperfileTheme get currentTheme => _currentTheme;
  String get currentFocus => _currentFocus;
  int get activePanelIndex => _activePanelIndex;
  bool get showMetadataPanel => _showMetadataPanel;
  bool get showSidebar => _showSidebar;
  bool get visualSelectMode => _visualSelectMode;
  List<PanelState> get panels => List.unmodifiable(_panels);
  List<ProcessItem> get processes => List.unmodifiable(_processes);
  List<String> get clipboardPaths => List.unmodifiable(_clipboardPaths);
  bool get isCutOperation => _isCutOperation;

  PanelState? get activePanel {
    if (_panels.isEmpty) return null;
    if (_activePanelIndex >= 0 && _activePanelIndex < _panels.length) {
      return _panels[_activePanelIndex];
    }
    return _panels.first;
  }

  Set<String> getSelectedPaths(String panelId) {
    return _selectedPathsPerPanel[panelId] ?? {};
  }

  SuperfileTheme getEffectiveTheme(BuildContext context) {
    if (_currentTheme.isSystemTheme) {
      final brightness = MediaQuery.of(context).platformBrightness;
      return brightness == Brightness.light
          ? SuperfileTheme.catppuccinLatte
          : SuperfileTheme.catppuccinMocha;
    }
    return _currentTheme;
  }

  SuperfileStateManager() {
    _initializeDefaultPanels();
    _loadPersistentConfig();
  }

  Future<void> _loadPersistentConfig() async {
    try {
      final home = Platform.environment['HOME'] ?? Directory.current.path;
      final configFile = File(p.join(home, '.superfile_gui_config.json'));
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final data = json.decode(content) as Map<String, dynamic>;

        if (data.containsKey('themeName')) {
          _currentTheme = SuperfileTheme.getThemeByName(data['themeName'] as String);
        }
        if (data.containsKey('showSidebar')) {
          _showSidebar = data['showSidebar'] as bool;
        }
        if (data.containsKey('showMetadataPanel')) {
          _showMetadataPanel = data['showMetadataPanel'] as bool;
        }
        if (data.containsKey('lastPath') && _panels.isNotEmpty) {
          final lastPath = data['lastPath'] as String;
          if (Directory(lastPath).existsSync()) {
            await navigateTo(_panels.first.panelId, lastPath);
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _savePersistentConfig() async {
    try {
      final home = Platform.environment['HOME'] ?? Directory.current.path;
      final configFile = File(p.join(home, '.superfile_gui_config.json'));
      final data = {
        'themeName': _currentTheme.name,
        'showSidebar': _showSidebar,
        'showMetadataPanel': _showMetadataPanel,
        'lastPath': activePanel?.currentPath ?? '',
      };
      await configFile.writeAsString(json.encode(data));
    } catch (_) {}
  }

  void _initializeDefaultPanels() {
    final home = Platform.environment['HOME'] ?? Directory.current.path;
    final defaultPanel = PanelState(
      panelId: 'panel_0',
      currentPath: home,
      history: [home],
      historyIndex: 0,
    );
    _panels.add(defaultPanel);
    _loadDirectoryForPanel('panel_0', home);
  }

  // --- Theme Controls ---
  void setTheme(SuperfileTheme theme) {
    _currentTheme = theme;
    notifyListeners();
    _savePersistentConfig();
  }

  // --- Focus Controls ---
  void setFocus(String focusTarget) {
    _currentFocus = focusTarget;
    if (focusTarget.startsWith('panel_')) {
      final index = int.tryParse(focusTarget.replaceFirst('panel_', ''));
      if (index != null && index >= 0 && index < _panels.length) {
        _activePanelIndex = index;
      }
    }
    notifyListeners();
  }

  void cycleFocus() {
    if (_panels.isEmpty) return;
    _activePanelIndex = (_activePanelIndex + 1) % _panels.length;
    _currentFocus = 'panel_$_activePanelIndex';
    notifyListeners();
  }

  void cycleFocusPrevious() {
    if (_panels.isEmpty) return;
    _activePanelIndex = (_activePanelIndex - 1 + _panels.length) % _panels.length;
    _currentFocus = 'panel_$_activePanelIndex';
    notifyListeners();
  }

  void toggleMetadataPanel() {
    _showMetadataPanel = !_showMetadataPanel;
    notifyListeners();
    _savePersistentConfig();
  }

  void toggleSidebar() {
    _showSidebar = !_showSidebar;
    notifyListeners();
    _savePersistentConfig();
  }

  // --- Panel Management (Split Views - Max 3 Tabs) ---
  void createNewPanel() {
    if (_panels.length >= 3) return; // Strict max 3 tabs constraint

    final id = 'panel_${_panels.length}';
    final initialPath = activePanel?.currentPath ?? Directory.current.path;
    final newPanel = PanelState(
      panelId: id,
      currentPath: initialPath,
      history: [initialPath],
    );
    _panels.add(newPanel);
    _activePanelIndex = _panels.length - 1;
    _currentFocus = id;
    notifyListeners();
    _loadDirectoryForPanel(id, initialPath);
  }

  void closeActivePanel() {
    closePanelAtIndex(_activePanelIndex);
  }

  void closePanelAtIndex(int index) {
    if (_panels.length <= 1) return; // Keep at least 1 panel open
    if (index < 0 || index >= _panels.length) return;

    _panels.removeAt(index);
    if (_activePanelIndex >= _panels.length) {
      _activePanelIndex = _panels.length - 1;
    }
    _currentFocus = 'panel_$_activePanelIndex';
    notifyListeners();
  }

  void setCursorIndex(String panelId, int newCursorIndex) {
    final index = _panels.indexWhere((p) => p.panelId == panelId);
    if (index == -1) return;

    final panel = _panels[index];
    final maxIndex = panel.filteredItems.isEmpty ? 0 : panel.filteredItems.length - 1;
    final clamped = newCursorIndex.clamp(0, maxIndex);

    _panels[index] = panel.copyWith(cursorIndex: clamped);
    notifyListeners();
  }

  final Map<String, Map<String, int>> _savedCursorPositionsPerPath = {};

  // --- Directory Navigation ---
  Future<void> navigateTo(String panelId, String newPath) async {
    final index = _panels.indexWhere((p) => p.panelId == panelId);
    if (index == -1) return;

    final panel = _panels[index];

    // Save cursor position of current path before leaving
    final panelMap = _savedCursorPositionsPerPath.putIfAbsent(panelId, () => {});
    panelMap[panel.currentPath] = panel.cursorIndex;

    // Check if we are navigating back to a parent folder
    final oldPath = panel.currentPath;
    final history = List<String>.from(panel.history);
    if (history.isEmpty || history.last != newPath) {
      history.add(newPath);
    }

    _panels[index] = panel.copyWith(
      currentPath: newPath,
      history: history,
      historyIndex: history.length - 1,
      cursorIndex: 0,
      searchFilter: '',
    );
    notifyListeners();

    await _loadDirectoryForPanel(panelId, newPath, previousSubPath: oldPath);
    _savePersistentConfig();
  }

  Future<void> navigateParent(String panelId) async {
    final panel = _panels.firstWhere((p) => p.panelId == panelId);
    final parentDir = Directory(panel.currentPath).parent.path;
    if (parentDir != panel.currentPath) {
      await navigateTo(panelId, parentDir);
    }
  }

  Future<void> openCurrentSelectedItem(String panelId) async {
    final panel = _panels.firstWhere((p) => p.panelId == panelId);
    final item = panel.currentItem;
    if (item == null) return;

    if (item.isDirectory) {
      await navigateTo(panelId, item.path);
    } else {
      await openFileWithDefaultApp(item.path);
    }
  }

  static Future<void> openFileWithDefaultApp(String filePath) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [filePath]);
      }
    } catch (_) {}
  }

  Future<void> _loadDirectoryForPanel(String panelId, String path, {String? previousSubPath}) async {
    final items = await FileIsolates.readDirectory(path);
    final index = _panels.indexWhere((p) => p.panelId == panelId);
    if (index != -1) {
      final panel = _panels[index];
      
      // Determine restored cursor index
      int targetCursorIndex = 0;
      final panelMap = _savedCursorPositionsPerPath[panelId];

      if (panelMap != null && panelMap.containsKey(path)) {
        targetCursorIndex = panelMap[path]!;
      } else if (previousSubPath != null && p.isWithin(path, previousSubPath)) {
        // Find index of the subdirectory we just came back from
        final targetIndex = items.indexWhere((item) => item.path == previousSubPath || p.isWithin(item.path, previousSubPath));
        if (targetIndex != -1) {
          targetCursorIndex = targetIndex;
        }
      }

      final maxIndex = items.isEmpty ? 0 : items.length - 1;
      targetCursorIndex = targetCursorIndex.clamp(0, maxIndex);

      _panels[index] = panel.copyWith(
        items: items,
        cursorIndex: targetCursorIndex,
      );
      notifyListeners();
    }
  }

  void refreshActivePanel() {
    final ap = activePanel;
    if (ap != null) {
      _loadDirectoryForPanel(ap.panelId, ap.currentPath);
    }
  }

  // --- Cursor & Selection Controls ---
  void moveCursorUp() {
    final ap = activePanel;
    if (ap == null) return;

    final index = _panels.indexOf(ap);
    final count = ap.filteredItems.length;
    if (count == 0) return;

    final newIndex = (ap.cursorIndex - 1).clamp(0, count - 1);
    _panels[index] = ap.copyWith(cursorIndex: newIndex);

    if (_visualSelectMode) {
      final currentPath = ap.filteredItems[newIndex].path;
      final set = _selectedPathsPerPanel.putIfAbsent(ap.panelId, () => {});
      set.add(currentPath);
    }
    notifyListeners();
  }

  void moveCursorDown() {
    final ap = activePanel;
    if (ap == null) return;

    final index = _panels.indexOf(ap);
    final count = ap.filteredItems.length;
    if (count == 0) return;

    final newIndex = (ap.cursorIndex + 1).clamp(0, count - 1);
    _panels[index] = ap.copyWith(cursorIndex: newIndex);

    if (_visualSelectMode) {
      final currentPath = ap.filteredItems[newIndex].path;
      final set = _selectedPathsPerPanel.putIfAbsent(ap.panelId, () => {});
      set.add(currentPath);
    }
    notifyListeners();
  }

  void toggleVisualSelectMode() {
    _visualSelectMode = !_visualSelectMode;
    final ap = activePanel;
    if (ap != null) {
      if (_visualSelectMode) {
        final item = ap.currentItem;
        if (item != null) {
          final set = _selectedPathsPerPanel.putIfAbsent(ap.panelId, () => {});
          set.add(item.path);
        }
      } else {
        // Exiting visual select mode clears selection for current panel
        _selectedPathsPerPanel[ap.panelId]?.clear();
      }
    }
    notifyListeners();
  }

  void cancelAllActions() {
    _visualSelectMode = false;
    _selectedPathsPerPanel.clear();
    _clipboardPaths = [];
    _isCutOperation = false;

    final ap = activePanel;
    if (ap != null) {
      final index = _panels.indexOf(ap);
      _panels[index] = ap.copyWith(searchFilter: '', isSearching: false);
    }
    notifyListeners();
  }

  void selectAllInActivePanel() {
    final ap = activePanel;
    if (ap == null) return;
    final set = _selectedPathsPerPanel.putIfAbsent(ap.panelId, () => {});
    set.clear();
    for (final item in ap.filteredItems) {
      set.add(item.path);
    }
    _visualSelectMode = true;
    notifyListeners();
  }

  void clearSelection(String panelId) {
    _selectedPathsPerPanel[panelId]?.clear();
    _visualSelectMode = false;
    notifyListeners();
  }

  void toggleItemSelection(String panelId, String itemPath) {
    final set = _selectedPathsPerPanel.putIfAbsent(panelId, () => {});
    if (set.contains(itemPath)) {
      set.remove(itemPath);
    } else {
      set.add(itemPath);
    }
    notifyListeners();
  }

  void toggleHiddenFiles() {
    final ap = activePanel;
    if (ap == null) return;
    final index = _panels.indexOf(ap);
    _panels[index] = ap.copyWith(showHiddenFiles: !ap.showHiddenFiles);
    notifyListeners();
  }

  void setSearchFilter(String query) {
    final ap = activePanel;
    if (ap == null) return;
    final index = _panels.indexOf(ap);
    _panels[index] = ap.copyWith(searchFilter: query, cursorIndex: 0);
    notifyListeners();
  }

  void toggleReverseSort() {
    final ap = activePanel;
    if (ap == null) return;
    final index = _panels.indexOf(ap);
    _panels[index] = ap.copyWith(isReverseSort: !ap.isReverseSort);
    notifyListeners();
  }

  void cycleSortMode() {
    final ap = activePanel;
    if (ap == null) return;
    final index = _panels.indexOf(ap);
    final nextSort = FileSortMode.values[(ap.sortMode.index + 1) % FileSortMode.values.length];
    _panels[index] = ap.copyWith(sortMode: nextSort);
    notifyListeners();
  }

  // --- Clipboard Operations ---
  void copySelected() {
    final ap = activePanel;
    if (ap == null) return;
    final selected = getSelectedPaths(ap.panelId);
    if (selected.isNotEmpty) {
      _clipboardPaths = selected.toList();
    } else if (ap.currentItem != null) {
      _clipboardPaths = [ap.currentItem!.path];
    }
    _isCutOperation = false;
    notifyListeners();
  }

  void cutSelected() {
    copySelected();
    _isCutOperation = true;
    notifyListeners();
  }

  Future<void> pasteClipboard() async {
    final ap = activePanel;
    if (ap == null || _clipboardPaths.isEmpty) return;

    final targetDir = ap.currentPath;
    final procId = DateTime.now().millisecondsSinceEpoch.toString();
    final processItem = ProcessItem(
      id: procId,
      title: '${_isCutOperation ? 'Moving' : 'Copying'} ${_clipboardPaths.length} items',
      type: _isCutOperation ? ProcessType.move : ProcessType.copy,
      status: ProcessStatus.running,
    );

    _processes.add(processItem);
    notifyListeners();

    try {
      await FileIsolates.copyItems(
        sourcePaths: _clipboardPaths,
        targetDirectory: targetDir,
        onProgress: (copied, total) {
          final pIndex = _processes.indexWhere((p) => p.id == procId);
          if (pIndex != -1) {
            final progress = total > 0 ? (copied / total) : 1.0;
            _processes[pIndex] = _processes[pIndex].copyWith(
              progress: progress,
              processedBytes: copied,
              totalBytes: total,
            );
            notifyListeners();
          }
        },
      );

      if (_isCutOperation) {
        await FileIsolates.deleteItems(_clipboardPaths);
        _clipboardPaths = [];
        _isCutOperation = false;
      }

      final pIndex = _processes.indexWhere((p) => p.id == procId);
      if (pIndex != -1) {
        _processes[pIndex] = _processes[pIndex].copyWith(
          status: ProcessStatus.completed,
          progress: 1.0,
        );
        notifyListeners();
      }

      // Automatically clear completed process tab after 5 seconds
      final targetProcId = procId;
      Future.delayed(const Duration(seconds: 5), () {
        _processes.removeWhere((p) => p.id == targetProcId);
        notifyListeners();
      });
    } catch (e) {
      final pIndex = _processes.indexWhere((p) => p.id == procId);
      if (pIndex != -1) {
        _processes[pIndex] = _processes[pIndex].copyWith(
          status: ProcessStatus.failed,
          errorMessage: e.toString(),
        );
      }
    }

    refreshActivePanel();
    notifyListeners();
  }

  // --- CRUD File Operations ---
  Future<void> deleteSelected({bool permanent = false}) async {
    final ap = activePanel;
    if (ap == null) return;

    final selected = getSelectedPaths(ap.panelId);
    final targets = selected.isNotEmpty
        ? selected.toList()
        : (ap.currentItem != null ? [ap.currentItem!.path] : <String>[]);

    if (targets.isEmpty) return;

    await FileIsolates.deleteItems(targets);
    _selectedPathsPerPanel[ap.panelId]?.clear();
    refreshActivePanel();
  }

  Future<void> createNewItem(String name, {required bool isDirectory}) async {
    final ap = activePanel;
    if (ap == null) return;

    final newPath = p.join(ap.currentPath, name);
    if (isDirectory) {
      await Directory(newPath).create(recursive: true);
    } else {
      await File(newPath).create(recursive: true);
    }
    refreshActivePanel();
  }

  Future<void> renameSelectedItem(String newName) async {
    final ap = activePanel;
    if (ap == null || ap.currentItem == null) return;

    final oldPath = ap.currentItem!.path;
    final targetPath = p.join(ap.currentPath, newName);

    final type = FileSystemEntity.typeSync(oldPath);
    if (type == FileSystemEntityType.file) {
      await File(oldPath).rename(targetPath);
    } else if (type == FileSystemEntityType.directory) {
      await Directory(oldPath).rename(targetPath);
    }
    refreshActivePanel();
  }

  // --- Compression Operations ---
  Future<void> compressSelectedToZip(String zipName) async {
    final ap = activePanel;
    if (ap == null) return;
    final selected = getSelectedPaths(ap.panelId);
    final targets = selected.isNotEmpty
        ? selected.toList()
        : (ap.currentItem != null ? [ap.currentItem!.path] : <String>[]);
    if (targets.isEmpty) return;

    final targetZip = zipName.endsWith('.zip')
        ? p.join(ap.currentPath, zipName)
        : p.join(ap.currentPath, '$zipName.zip');

    final procId = DateTime.now().millisecondsSinceEpoch.toString();
    _processes.add(ProcessItem(
      id: procId,
      title: 'Compressing ${targets.length} items -> ${p.basename(targetZip)}',
      type: ProcessType.copy,
      status: ProcessStatus.running,
    ));
    notifyListeners();

    try {
      await FileIsolates.compressToZip(sourcePaths: targets, targetZipPath: targetZip);
      final index = _processes.indexWhere((p) => p.id == procId);
      if (index != -1) {
        _processes[index] = _processes[index].copyWith(status: ProcessStatus.completed, progress: 1.0);
        notifyListeners();
      }
      Future.delayed(const Duration(seconds: 5), () {
        _processes.removeWhere((p) => p.id == procId);
        notifyListeners();
      });
      refreshActivePanel();
    } catch (e) {
      final index = _processes.indexWhere((p) => p.id == procId);
      if (index != -1) {
        _processes[index] = _processes[index].copyWith(status: ProcessStatus.failed, errorMessage: e.toString());
        notifyListeners();
      }
    }
  }

  Future<void> extractSelectedZip() async {
    final ap = activePanel;
    final item = ap?.currentItem;
    if (ap == null || item == null || item.extension.toLowerCase() != 'zip') return;

    final procId = DateTime.now().millisecondsSinceEpoch.toString();
    _processes.add(ProcessItem(
      id: procId,
      title: 'Extracting ${item.name}',
      type: ProcessType.copy,
      status: ProcessStatus.running,
    ));
    notifyListeners();

    try {
      await FileIsolates.extractZip(zipPath: item.path, targetDir: ap.currentPath);
      final index = _processes.indexWhere((p) => p.id == procId);
      if (index != -1) {
        _processes[index] = _processes[index].copyWith(status: ProcessStatus.completed, progress: 1.0);
        notifyListeners();
      }
      Future.delayed(const Duration(seconds: 5), () {
        _processes.removeWhere((p) => p.id == procId);
        notifyListeners();
      });
      refreshActivePanel();
    } catch (e) {
      final index = _processes.indexWhere((p) => p.id == procId);
      if (index != -1) {
        _processes[index] = _processes[index].copyWith(status: ProcessStatus.failed, errorMessage: e.toString());
        notifyListeners();
      }
    }
  }
}

import 'file_item.dart';

class PanelState {
  final String panelId;
  final String currentPath;
  final List<String> history;
  final int historyIndex;
  final int cursorIndex;
  final List<FileItem> items;
  final bool showHiddenFiles;
  final String searchFilter;
  final FileSortMode sortMode;
  final bool isReverseSort;
  final bool isSearching;

  const PanelState({
    required this.panelId,
    required this.currentPath,
    this.history = const [],
    this.historyIndex = 0,
    this.cursorIndex = 0,
    this.items = const [],
    this.showHiddenFiles = false,
    this.searchFilter = '',
    this.sortMode = FileSortMode.name,
    this.isReverseSort = false,
    this.isSearching = false,
  });

  List<FileItem> get filteredItems {
    var result = items.where((item) {
      if (!showHiddenFiles && item.isHidden) return false;
      if (searchFilter.isNotEmpty) {
        return item.name.toLowerCase().contains(searchFilter.toLowerCase());
      }
      return true;
    }).toList();

    result.sort((a, b) {
      // Directories always come first in Superfile layout
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;

      int comp = 0;
      switch (sortMode) {
        case FileSortMode.name:
          comp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case FileSortMode.size:
          comp = a.size.compareTo(b.size);
          break;
        case FileSortMode.date:
          comp = a.modified.compareTo(b.modified);
          break;
        case FileSortMode.type:
          comp = a.extension.compareTo(b.extension);
          break;
      }
      return isReverseSort ? -comp : comp;
    });

    return result;
  }

  FileItem? get currentItem {
    final list = filteredItems;
    if (cursorIndex >= 0 && cursorIndex < list.length) {
      return list[cursorIndex];
    }
    return null;
  }

  PanelState copyWith({
    String? currentPath,
    List<String>? history,
    int? historyIndex,
    int? cursorIndex,
    List<FileItem>? items,
    bool? showHiddenFiles,
    String? searchFilter,
    FileSortMode? sortMode,
    bool? isReverseSort,
    bool? isSearching,
  }) {
    return PanelState(
      panelId: panelId,
      currentPath: currentPath ?? this.currentPath,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
      cursorIndex: cursorIndex ?? this.cursorIndex,
      items: items ?? this.items,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      searchFilter: searchFilter ?? this.searchFilter,
      sortMode: sortMode ?? this.sortMode,
      isReverseSort: isReverseSort ?? this.isReverseSort,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

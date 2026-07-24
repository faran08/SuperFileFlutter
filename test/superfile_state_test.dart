import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:superfile/core/state/superfile_state_manager.dart';
import 'package:superfile/core/theme/superfile_themes.dart';

void main() {
  group('SuperfileStateManager Unit Tests', () {
    late SuperfileStateManager manager;

    setUp(() {
      manager = SuperfileStateManager();
    });

    test('Initial state is correctly set up', () {
      expect(manager.panels.length, equals(1));
      expect(manager.currentTheme.name, equals('Catppuccin Mocha'));
      expect(manager.currentFocus, equals('panel_0'));
    });

    test('Theme switching updates currentTheme', () {
      manager.setTheme(SuperfileTheme.nord);
      expect(manager.currentTheme.name, equals('Nord'));

      manager.setTheme(SuperfileTheme.tokyoNight);
      expect(manager.currentTheme.name, equals('Tokyo Night'));
    });

    test('Split View creates and closes panels', () {
      expect(manager.panels.length, equals(1));

      manager.createNewPanel();
      expect(manager.panels.length, equals(2));
      expect(manager.activePanelIndex, equals(1));

      manager.closeActivePanel();
      expect(manager.panels.length, equals(1));
      expect(manager.activePanelIndex, equals(0));
    });

    test('Directory navigation updates currentPath', () async {
      final tempDir = Directory.systemTemp.createTempSync('superfile_test_');
      final panelId = manager.panels.first.panelId;

      await manager.navigateTo(panelId, tempDir.path);
      expect(manager.activePanel?.currentPath, equals(tempDir.path));

      tempDir.deleteSync(recursive: true);
    });

    test('Cursor movement stays within bounds', () {
      manager.moveCursorUp();
      expect(manager.activePanel?.cursorIndex, equals(0));

      manager.moveCursorDown();
      // Should not crash even if items are empty or small
    });
  });
}

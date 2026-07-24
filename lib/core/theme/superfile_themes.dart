import 'package:flutter/material.dart';

class SuperfileTheme {
  final String name;
  final bool isSystemTheme;
  final Color fullScreenBg;
  final Color fullScreenFg;
  final Color filePanelBg;
  final Color filePanelFg;
  final Color filePanelBorder;
  final Color filePanelBorderActive;
  final Color filePanelTopDirectoryIcon;
  final Color filePanelTopPath;
  final Color filePanelItemSelectedFg;
  final Color filePanelItemSelectedBg;
  final Color sidebarBg;
  final Color sidebarFg;
  final Color sidebarTitle;
  final Color sidebarBorder;
  final Color sidebarBorderActive;
  final Color sidebarItemSelectedFg;
  final Color sidebarItemSelectedBg;
  final Color footerBg;
  final Color footerFg;
  final Color footerBorder;
  final Color footerBorderActive;
  final Color modalBg;
  final Color modalFg;
  final Color modalBorderActive;
  final Color modalConfirmBg;
  final Color modalConfirmFg;
  final Color modalCancelBg;
  final Color modalCancelFg;
  final Color cursor;
  final Color correct;
  final Color error;
  final Color hint;
  final List<Color> gradientColor;

  const SuperfileTheme({
    required this.name,
    this.isSystemTheme = false,
    required this.fullScreenBg,
    required this.fullScreenFg,
    required this.filePanelBg,
    required this.filePanelFg,
    required this.filePanelBorder,
    required this.filePanelBorderActive,
    required this.filePanelTopDirectoryIcon,
    required this.filePanelTopPath,
    required this.filePanelItemSelectedFg,
    required this.filePanelItemSelectedBg,
    required this.sidebarBg,
    required this.sidebarFg,
    required this.sidebarTitle,
    required this.sidebarBorder,
    required this.sidebarBorderActive,
    required this.sidebarItemSelectedFg,
    required this.sidebarItemSelectedBg,
    required this.footerBg,
    required this.footerFg,
    required this.footerBorder,
    required this.footerBorderActive,
    required this.modalBg,
    required this.modalFg,
    required this.modalBorderActive,
    required this.modalConfirmBg,
    required this.modalConfirmFg,
    required this.modalCancelBg,
    required this.modalCancelFg,
    required this.cursor,
    required this.correct,
    required this.error,
    required this.hint,
    required this.gradientColor,
  });

  static Color _hex(String hexStr) {
    if (hexStr.isEmpty) return Colors.transparent;
    final clean = hexStr.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  // System Auto Theme Placeholder
  static final systemTheme = SuperfileTheme(
    name: 'System (Auto)',
    isSystemTheme: true,
    fullScreenBg: _hex('1e1e2e'),
    fullScreenFg: _hex('a6adc8'),
    filePanelBg: _hex('1e1e2e'),
    filePanelFg: _hex('a6adc8'),
    filePanelBorder: _hex('6c7086'),
    filePanelBorderActive: _hex('b4befe'),
    filePanelTopDirectoryIcon: _hex('a6e3a1'),
    filePanelTopPath: _hex('89b5fa'),
    filePanelItemSelectedFg: _hex('98D0FD'),
    filePanelItemSelectedBg: _hex('313244'),
    sidebarBg: _hex('1e1e2e'),
    sidebarFg: _hex('a6adc8'),
    sidebarTitle: _hex('74c7ec'),
    sidebarBorder: _hex('313244'),
    sidebarBorderActive: _hex('f38ba8'),
    sidebarItemSelectedFg: _hex('A6DBF7'),
    sidebarItemSelectedBg: _hex('313244'),
    footerBg: _hex('1e1e2e'),
    footerFg: _hex('a6adc8'),
    footerBorder: _hex('6c7086'),
    footerBorderActive: _hex('a6e3a1'),
    modalBg: _hex('1e1e2e'),
    modalFg: _hex('a6adc8'),
    modalBorderActive: _hex('868686'),
    modalConfirmBg: _hex('89dceb'),
    modalConfirmFg: _hex('11111b'),
    modalCancelBg: _hex('eba0ac'),
    modalCancelFg: _hex('11111b'),
    cursor: _hex('f5e0dc'),
    correct: _hex('a6e3a1'),
    error: _hex('f38ba8'),
    hint: _hex('73c7ec'),
    gradientColor: [_hex('89b4fa'), _hex('cba6f7')],
  );

  // Catppuccin Mocha Theme (Dark)
  static final catppuccinMocha = SuperfileTheme(
    name: 'Catppuccin Mocha',
    fullScreenBg: _hex('1e1e2e'),
    fullScreenFg: _hex('a6adc8'),
    filePanelBg: _hex('1e1e2e'),
    filePanelFg: _hex('a6adc8'),
    filePanelBorder: _hex('6c7086'),
    filePanelBorderActive: _hex('b4befe'),
    filePanelTopDirectoryIcon: _hex('a6e3a1'),
    filePanelTopPath: _hex('89b5fa'),
    filePanelItemSelectedFg: _hex('98D0FD'),
    filePanelItemSelectedBg: _hex('313244'),
    sidebarBg: _hex('1e1e2e'),
    sidebarFg: _hex('a6adc8'),
    sidebarTitle: _hex('74c7ec'),
    sidebarBorder: _hex('313244'),
    sidebarBorderActive: _hex('f38ba8'),
    sidebarItemSelectedFg: _hex('A6DBF7'),
    sidebarItemSelectedBg: _hex('313244'),
    footerBg: _hex('1e1e2e'),
    footerFg: _hex('a6adc8'),
    footerBorder: _hex('6c7086'),
    footerBorderActive: _hex('a6e3a1'),
    modalBg: _hex('1e1e2e'),
    modalFg: _hex('a6adc8'),
    modalBorderActive: _hex('868686'),
    modalConfirmBg: _hex('89dceb'),
    modalConfirmFg: _hex('11111b'),
    modalCancelBg: _hex('eba0ac'),
    modalCancelFg: _hex('11111b'),
    cursor: _hex('f5e0dc'),
    correct: _hex('a6e3a1'),
    error: _hex('f38ba8'),
    hint: _hex('73c7ec'),
    gradientColor: [_hex('89b4fa'), _hex('cba6f7')],
  );

  // Catppuccin Latte Theme (Light)
  static final catppuccinLatte = SuperfileTheme(
    name: 'Catppuccin Latte',
    fullScreenBg: _hex('eff1f5'),
    fullScreenFg: _hex('4c4f69'),
    filePanelBg: _hex('eff1f5'),
    filePanelFg: _hex('4c4f69'),
    filePanelBorder: _hex('bcc0cc'),
    filePanelBorderActive: _hex('1e66f5'),
    filePanelTopDirectoryIcon: _hex('40a02b'),
    filePanelTopPath: _hex('1e66f5'),
    filePanelItemSelectedFg: _hex('1e66f5'),
    filePanelItemSelectedBg: _hex('dce0e8'),
    sidebarBg: _hex('e6e9ef'),
    sidebarFg: _hex('4c4f69'),
    sidebarTitle: _hex('1e66f5'),
    sidebarBorder: _hex('ccd0da'),
    sidebarBorderActive: _hex('d20f39'),
    sidebarItemSelectedFg: _hex('1e66f5'),
    sidebarItemSelectedBg: _hex('dce0e8'),
    footerBg: _hex('e6e9ef'),
    footerFg: _hex('4c4f69'),
    footerBorder: _hex('bcc0cc'),
    footerBorderActive: _hex('40a02b'),
    modalBg: _hex('eff1f5'),
    modalFg: _hex('4c4f69'),
    modalBorderActive: _hex('1e66f5'),
    modalConfirmBg: _hex('1e66f5'),
    modalConfirmFg: _hex('eff1f5'),
    modalCancelBg: _hex('d20f39'),
    modalCancelFg: _hex('eff1f5'),
    cursor: _hex('dc8a78'),
    correct: _hex('40a02b'),
    error: _hex('d20f39'),
    hint: _hex('df8e1d'),
    gradientColor: [_hex('1e66f5'), _hex('8839ef')],
  );

  // Nord Theme
  static final nord = SuperfileTheme(
    name: 'Nord',
    fullScreenBg: _hex('2e3440'),
    fullScreenFg: _hex('d8dee9'),
    filePanelBg: _hex('2e3440'),
    filePanelFg: _hex('d8dee9'),
    filePanelBorder: _hex('4c566a'),
    filePanelBorderActive: _hex('88c0d0'),
    filePanelTopDirectoryIcon: _hex('a3be8c'),
    filePanelTopPath: _hex('81a1c1'),
    filePanelItemSelectedFg: _hex('88c0d0'),
    filePanelItemSelectedBg: _hex('3b4252'),
    sidebarBg: _hex('2e3440'),
    sidebarFg: _hex('d8dee9'),
    sidebarTitle: _hex('88c0d0'),
    sidebarBorder: _hex('3b4252'),
    sidebarBorderActive: _hex('bf616a'),
    sidebarItemSelectedFg: _hex('88c0d0'),
    sidebarItemSelectedBg: _hex('3b4252'),
    footerBg: _hex('2e3440'),
    footerFg: _hex('d8dee9'),
    footerBorder: _hex('4c566a'),
    footerBorderActive: _hex('a3be8c'),
    modalBg: _hex('2e3440'),
    modalFg: _hex('d8dee9'),
    modalBorderActive: _hex('88c0d0'),
    modalConfirmBg: _hex('a3be8c'),
    modalConfirmFg: _hex('2e3440'),
    modalCancelBg: _hex('bf616a'),
    modalCancelFg: _hex('2e3440'),
    cursor: _hex('eceff4'),
    correct: _hex('a3be8c'),
    error: _hex('bf616a'),
    hint: _hex('ebcb8b'),
    gradientColor: [_hex('88c0d0'), _hex('81a1c1')],
  );

  // Tokyo Night Theme
  static final tokyoNight = SuperfileTheme(
    name: 'Tokyo Night',
    fullScreenBg: _hex('1a1b26'),
    fullScreenFg: _hex('a9b1d6'),
    filePanelBg: _hex('1a1b26'),
    filePanelFg: _hex('a9b1d6'),
    filePanelBorder: _hex('414868'),
    filePanelBorderActive: _hex('7aa2f7'),
    filePanelTopDirectoryIcon: _hex('9ece6a'),
    filePanelTopPath: _hex('7dcfff'),
    filePanelItemSelectedFg: _hex('7aa2f7'),
    filePanelItemSelectedBg: _hex('24283b'),
    sidebarBg: _hex('1a1b26'),
    sidebarFg: _hex('a9b1d6'),
    sidebarTitle: _hex('7aa2f7'),
    sidebarBorder: _hex('24283b'),
    sidebarBorderActive: _hex('f7768e'),
    sidebarItemSelectedFg: _hex('7aa2f7'),
    sidebarItemSelectedBg: _hex('24283b'),
    footerBg: _hex('1a1b26'),
    footerFg: _hex('a9b1d6'),
    footerBorder: _hex('414868'),
    footerBorderActive: _hex('9ece6a'),
    modalBg: _hex('1a1b26'),
    modalFg: _hex('a9b1d6'),
    modalBorderActive: _hex('7aa2f7'),
    modalConfirmBg: _hex('9ece6a'),
    modalConfirmFg: _hex('1a1b26'),
    modalCancelBg: _hex('f7768e'),
    modalCancelFg: _hex('1a1b26'),
    cursor: _hex('c0caf5'),
    correct: _hex('9ece6a'),
    error: _hex('f7768e'),
    hint: _hex('e0af68'),
    gradientColor: [_hex('7aa2f7'), _hex('bb9af7')],
  );

  static List<SuperfileTheme> get allThemes => [
    systemTheme,
    catppuccinMocha,
    catppuccinLatte,
    nord,
    tokyoNight,
  ];

  static SuperfileTheme getThemeByName(String name) {
    return allThemes.firstWhere(
      (t) => t.name == name,
      orElse: () => systemTheme,
    );
  }
}

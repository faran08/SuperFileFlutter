import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/state/superfile_state_manager.dart';
import 'ui/widgets/document_preview_widget.dart';
import 'ui/widgets/footer_bar_widget.dart';
import 'ui/widgets/file_panel_widget.dart';
import 'ui/widgets/header_bar_widget.dart';
import 'ui/widgets/keyboard_shortcuts_listener.dart';
import 'ui/widgets/metadata_panel_widget.dart';
import 'ui/widgets/process_tracker_widget.dart';
import 'ui/widgets/sidebar_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SuperfileStateManager(),
      child: const SuperfileApp(),
    ),
  );
}

class SuperfileApp extends StatelessWidget {
  const SuperfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SuperfileStateManager>();
    final theme = manager.getEffectiveTheme(context);

    return MaterialApp(
      title: 'Superfile GUI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: theme.fullScreenBg.computeLuminance() > 0.5 ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: theme.fullScreenBg,
        fontFamily: 'monospace',
        useMaterial3: true,
      ),
      home: const SuperfileMainScreen(),
    );
  }
}

class SuperfileMainScreen extends StatelessWidget {
  const SuperfileMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SuperfileStateManager>();
    final theme = manager.getEffectiveTheme(context);

    return Scaffold(
      backgroundColor: theme.fullScreenBg,
      body: SafeArea(
        child: KeyboardShortcutsListener(
          child: Column(
            children: [
              // Top Header Navigation Bar
              const HeaderBarWidget(),

              // Main Workspace Row: [Sidebar | File Panels | Document View (Right)]
              Expanded(
                child: Row(
                  children: [
                    // Sidebar
                    if (manager.showSidebar) const SidebarWidget(),

                    // Multi-Panel File Explorer Split View
                    Expanded(
                      child: Row(
                        children: List.generate(manager.panels.length, (index) {
                          final panel = manager.panels[index];
                          final isFocused = manager.activePanelIndex == index;

                          return Expanded(
                            child: FilePanelWidget(
                              panel: panel,
                              isFocused: isFocused,
                            ),
                          );
                        }),
                      ),
                    ),

                    // Document View Panel on the Right (Text, Images, PDF, DOCX, PPTX)
                    if (manager.showMetadataPanel) const DocumentPreviewWidget(),
                  ],
                ),
              ),

              // Bottom Section: [Metadata Strip | Process Tracker | Footer Bar]
              const MetadataBottomWidget(),
              const ProcessTrackerWidget(),
              const FooterBarWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

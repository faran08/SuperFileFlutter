# Superfile Flutter Desktop: Agent Instruction Set

## Mission Objective
You are tasked with cloning the Go-based TUI file manager **Superfile** and reverse-engineering its visual layout, keyboard-centric UX, and core feature set into a high-performance **Flutter Desktop** application. The final product must operate exclusively on the local file system using native desktop bindings, bypassing browser sandbox limitations.

## Phase 1: Repository Ingestion & UX Analysis
1. **Clone the Source:** Execute `git clone https://github.com/yorukot/superfile.git --depth=1` into a temporary analysis directory.
2. **Analyze TUI Structure:** Review the source code (specifically the Bubble Tea UI components) to understand the layout geometry:
   - Sidebar (pinned directories, disks).
   - Main File Explorer (multi-panel support).
   - Metadata Panel (file stats, permissions, type).
   - Process Tracker (active file operations).
3. **Extract Keymaps & Themes:** Extract the default Vim-style keyboard mappings and the base color palettes (e.g., Catppuccin, Nord) used in the original application.

## Phase 2: Workspace Initialization
1. **Initialize Flutter:** Create a new Flutter project optimized for desktop environments: `flutter create --platforms=macos,linux,windows superfile_gui`.
2. **Clean Boilerplate:** Remove all default counter app logic. Set up a strictly typed, state-managed architecture (Riverpod is strongly recommended) suitable for multi-panel state synchronization.
3. **Configure Desktop Bounds:** Implement a window manager package (like `window_manager`) to enforce minimum window dimensions (e.g., 800x600) to ensure the multi-panel layout does not collapse.

## Phase 3: Architectural Constraints (Strict Enforcement)
You must adhere to the following performance rules when building the application. Failure to do so will result in UI thread locking and memory overflow.

1. **Massive Directory Handling:**
   - **Rule:** Never use standard `Column` or `ListView` widgets for file trees.
   - **Implementation:** You must use `ListView.builder`. Explicitly define the `itemExtent` property for every file row to ensure Flutter can calculate scroll geometry instantly without rendering off-screen widgets.
2. **Asynchronous I/O Operations:**
   - **Rule:** The main Dart UI thread must never be blocked by heavy file system tasks.
   - **Implementation:** Spawn Dart **Isolates** using `compute()` or `Isolate.run()` for any heavy operations, including recursive directory size calculations, deep file searches, or bulk file transfers. Pass data back to the UI thread via message passing.
3. **Targeted State Rebuilds:**
   - **Rule:** High-frequency updates (e.g., the Process Tracker progress bar, real-time metadata rendering) must not trigger full widget tree rebuilds.
   - **Implementation:** Wrap rapidly updating widgets in `RepaintBoundary`. Use `ValueNotifier` and `ValueListenableBuilder` to isolate state changes precisely to the pixels that require updating.
4. **Memory Management:**
   - **Rule:** Prevent RAM bloat from image caching and file streams.
   - **Implementation:** Explicitly close all `File` and `Stream` objects in the `dispose()` methods of their respective controllers. If generating image previews, strictly limit the `ResizeImage` cache dimensions to the exact size of the preview panel.

## Phase 4: State Management Architecture (Riverpod Implementation)
To handle the complex multi-panel TUI behavior, structure the state using Riverpod to guarantee isolated component rebuilds:

1. **`panelFocusProvider` (StateProvider):** 
   - Tracks the active panel ID (e.g., `sidebar`, `panel_1`, `panel_2`). The global keyboard listener uses this to route input events exclusively to the active panel's controller.
2. **`directoryStateProviderFamily` (AsyncNotifierProvider):** 
   - A family provider that takes a panel ID and manages its specific `Directory` state. It fetches files natively via `dart:io`, sorts them, and caches the result. 
   - Ensures that switching directories in Panel A does not rebuild Panel B.
3. **`processTrackerProvider` (NotifierProvider):** 
   - Manages the state of background Isolates handling file transfers. It exposes a queue of ongoing tasks and updates their progress values incrementally. Widgets in the Process Tracker panel listen to this provider to animate progress bars without forcing the main file explorer to repaint.
4. **`selectionStateProviderFamily` (StateNotifierProvider):**
   - Manages the Vim-style visual selection mode (`V`), storing a Set of selected file paths per panel, enabling bulk operations (copy/cut/delete).

## Phase 5: Core Feature Implementation
1. **Keyboard-First Navigation:** Implement a global `HardwareKeyboard` listener. Map standard Vim bindings (`j`/`k` for up/down, `h`/`l` for parent/child directories, `/` for search, `ctrl+x/c/v` for file operations) to bypass the need for mouse clicks. Route these inputs based on the `panelFocusProvider`.
2. **File System Abstraction:** Utilize Dart's `dart:io` library for all core directory reads, metadata extraction, and CRUD operations. 
3. **Multi-Panel Layout:** Build a dynamic horizontal splitting widget. Allow the user to spawn new panels (`ctrl+n` equivalent) that inherit a new instance of the `directoryStateProviderFamily`.

## Phase 6: Build & Test Execution
1. Compile a release build for the host operating system to test Impeller/Skia rendering performance.
2. Execute a stress test by opening a directory containing >10,000 files to verify the `ListView.builder` implementation, `itemExtent` optimizations, and scrolling framerate without RAM bloat.

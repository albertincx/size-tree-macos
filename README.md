[🇷🇺 Читать на русском](README_RU.md)

# FolderViewer

A fast, lightweight, and modern **SwiftUI** app for macOS designed to inspect folder and file trees, calculate disk sizes, and cache them for instant access with on-demand recalculation.

---

## ✨ Features

- 🌳 **Interactive File & Folder Tree**:
  - Instant expand and collapse of subfolders.
  - Native macOS system file icons via `NSWorkspace`.
  - Displays file sizes and cumulative folder sizes.
  - Item count per directory.
  - **"Show files" toggle checkbox**: hide regular files to inspect only directory trees, or view both.
  - Sort by size (descending/ascending), name (A-Z/Z-A), or modification date.
  - Real-time search filter.

- ⚡ **Persistent Disk Size Caching**:
  - Folder sizes are cached locally on disk (`~/Library/Application Support/FolderViewer/folder_size_cache.json`).
  - Previously inspected folders open **instantly** without repeated disk I/O.
  - Cached directories display a **⚡ Cached** badge showing relative time since the last calculation.
  - Background asynchronous scanning for non-cached folders without freezing the UI.

- 🔄 **On-Demand Recalculation**:
  - **Toolbar "Recalculate Size" button**:
    - One click recalculates visible cached folders.
    - Dropdown options: *Recalculate Selected Folder*, *Recalculate All Visible*, *Recalculate Entire Cache*.
  - **Per-row recalculate icon (🔄)** on every folder item.
  - **Context Menu** (right click on any folder): *Recalculate Size*.
  - **Cache Management Dialog**: view cache size on disk, re-scan all entries, or wipe the cache clean.

- 🧭 **Path History & Navigation**:
  - **Back (⌘[)** and **Forward (⌘])** buttons.
  - Recent paths dropdown menu (`clock.arrow.circlepath`) in both header and toolbar.
  - Interactive recent folder cards on the welcome screen.
  - Persistent history across app launches.

- 🌐 **Bilingual (English & Russian)**:
  - Automatically matches the macOS system language (`Locale.preferredLanguages`).
  - Quick **RU / EN** toggle switch in the bottom status bar and cache dialog.

- 🍎 **macOS Native Integration**:
  - **Drag & Drop**: drag any folder from Finder directly into the app window.
  - Right-click actions: *Reveal in Finder*, *Open in Terminal*, *Copy Path*.
  - Clean SwiftUI design for macOS 14+ Sonoma & macOS 15+ Sequoia.

---

## 🚀 Quick Start

Run the prebuilt application:
```bash
./run.sh
```
or open the `.app` bundle directly:
```bash
open FolderViewer.app
```

---

## 🛠 Building from Source

### Requirements:
- macOS 14.0 or newer
- Swift 6.0+ (Xcode Command Line Tools)

To build the optimized release application bundle:
```bash
./build_app.sh
```

Or run directly via Swift Package Manager:
```bash
swift run
```

---

## 📄 License

MIT License

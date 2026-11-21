# System Data Cleaner

A macOS app to analyze and clean the "System Data" storage category on your Mac. Built with SwiftUI.

## What It Does

macOS shows a "System Data" category in Storage Settings that can grow to tens or hundreds of gigabytes. This app scans and identifies what's actually using that space, letting you selectively clean items you don't need.

## Features

- **Storage Scanning** - Analyzes 23 categories of system data including caches, logs, Time Machine snapshots, developer data, and more
- **Visual Breakdown** - Color-coded bar chart showing what's using space (hover for details)
- **Detailed Explanations** - Click the ? icon on any category to learn what it is, what happens if you delete it, and safety recommendations
- **Claude AI Integration** - Ask Claude about any file or folder to understand what it is and whether it's safe to delete
- **Selective Cleanup** - Choose exactly what to delete with safety warnings for risky items
- **Time Machine Snapshots** - View and delete local APFS snapshots that can consume significant space

## Categories Scanned

| Category | Safety | Description |
|----------|--------|-------------|
| Time Machine Snapshots | Safe | Local APFS snapshots |
| User Caches | Safe | App temporary data |
| System Caches | Moderate | macOS temporary data |
| Log Files | Safe | System and app logs |
| Temporary Files | Safe | Short-lived working files |
| Developer Data | Moderate | Xcode, simulators, package caches |
| iOS/Device Backups | Danger | iPhone/iPad backups |
| Application Support | Danger | App databases and settings |
| Mail Data | Danger | Email attachments and cache |
| Messages & Attachments | Danger | iMessage photos/videos |
| Spotlight Index | Read Only | Search index |
| Browser Data | Moderate | Safari, Chrome, Firefox, Arc data |
| Downloads | Caution | Your downloaded files |
| App Containers | Caution | Sandboxed app storage |
| Virtual Memory | Read Only | Swap and sleep files |
| iCloud Cache | Moderate | Local iCloud Drive copies |
| Photos Library Cache | Caution | Thumbnails and analysis data |
| Music & Podcast Cache | Caution | Downloaded media |
| Saved Application State | Safe | Window positions and states |
| Font Caches | Safe | Font rendering cache |
| Siri & Dictation Data | Caution | Speech recognition models |
| Language Resources | Read Only | Translation and localization |
| System Temp Folders | Moderate | /private/var/folders |

## Requirements

- macOS 13.0 or later
- Full Disk Access (recommended for complete scan results)

## Setup

1. Open `SystemDataCleaner.xcodeproj` in Xcode
2. Build and run (Cmd+R)
3. Grant Full Disk Access when prompted, or manually:
   - System Settings → Privacy & Security → Full Disk Access
   - Click + and add SystemDataCleaner.app
   - Restart the app

## Claude AI Integration

The app includes an optional Claude AI panel to ask questions about files and folders:

1. Click the key icon in the Claude panel
2. Enter your Anthropic API key (get one at [console.anthropic.com](https://console.anthropic.com))
3. Select any item in the list
4. Click "What is this?" or type a custom question

Your API key is stored locally in Keychain and never shared.

## Why System Data Appears Large

macOS "System Data" includes many things this app cannot access or delete:

- APFS container metadata
- Firmware and core OS files
- SIP-protected system caches
- Spotlight metadata
- FileVault encryption overhead

This app focuses on the portions you *can* safely manage.

## Safety Notes

- **Always have a backup** before deleting system files
- Items marked "Danger" may cause data loss - read the warnings
- "Read Only" items cannot be deleted (managed by macOS)
- When in doubt, use the Claude AI panel to ask about specific items

## License

MIT

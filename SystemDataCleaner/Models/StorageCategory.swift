import Foundation

enum StorageCategoryType: String, CaseIterable, Identifiable {
    case timeMachineSnapshots = "Time Machine Snapshots"
    case userCaches = "User Caches"
    case systemCaches = "System Caches"
    case logFiles = "Log Files"
    case tempFiles = "Temporary Files"
    case developerData = "Developer Data"
    case iosBackups = "iOS/Device Backups"
    case applicationSupport = "Application Support"
    case mailData = "Mail Data"
    case messagesData = "Messages & Attachments"
    case spotlightIndex = "Spotlight Index"
    case browserData = "Browser Data"
    case downloads = "Downloads"
    case appContainers = "App Containers"
    case virtualMemory = "Virtual Memory & Swap"
    case iCloudCache = "iCloud Cache"
    case photosCache = "Photos Library Cache"
    case musicPodcastCache = "Music & Podcast Cache"
    case savedAppState = "Saved Application State"
    case fontCaches = "Font Caches"
    case siriDictation = "Siri & Dictation Data"
    case languageResources = "Language Resources"
    case systemTempFolders = "System Temp Folders"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .timeMachineSnapshots: return "clock.arrow.circlepath"
        case .userCaches: return "archivebox"
        case .systemCaches: return "gearshape.2"
        case .logFiles: return "doc.text"
        case .tempFiles: return "trash"
        case .developerData: return "hammer"
        case .iosBackups: return "iphone"
        case .applicationSupport: return "app.badge"
        case .mailData: return "envelope"
        case .messagesData: return "message"
        case .spotlightIndex: return "magnifyingglass"
        case .browserData: return "safari"
        case .downloads: return "arrow.down.circle"
        case .appContainers: return "shippingbox"
        case .virtualMemory: return "memorychip"
        case .iCloudCache: return "icloud"
        case .photosCache: return "photo"
        case .musicPodcastCache: return "music.note"
        case .savedAppState: return "square.stack.3d.up"
        case .fontCaches: return "textformat"
        case .siriDictation: return "mic"
        case .languageResources: return "globe"
        case .systemTempFolders: return "folder.badge.gearshape"
        }
    }

    var description: String {
        switch self {
        case .timeMachineSnapshots:
            return "Local APFS snapshots created hourly by Time Machine"
        case .userCaches:
            return "Temporary data apps store to load faster"
        case .systemCaches:
            return "System-level temporary data"
        case .logFiles:
            return "Records of system and app activity"
        case .tempFiles:
            return "Short-lived files, usually cleared on reboot"
        case .developerData:
            return "Build files, simulators, and package caches"
        case .iosBackups:
            return "Full backups of your iPhone/iPad"
        case .applicationSupport:
            return "App databases, settings, and support files"
        case .mailData:
            return "Email attachments and downloaded content"
        case .messagesData:
            return "Photos and videos from iMessage"
        case .spotlightIndex:
            return "Search index for fast file finding"
        case .browserData:
            return "Website caches, cookies, and history"
        case .downloads:
            return "Files you've downloaded from the internet"
        case .appContainers:
            return "Isolated storage for sandboxed apps"
        case .virtualMemory:
            return "RAM overflow and sleep restore data"
        case .iCloudCache:
            return "Local copies of iCloud Drive files and sync data"
        case .photosCache:
            return "Thumbnails, faces data, and photo analysis"
        case .musicPodcastCache:
            return "Downloaded songs, podcasts, and artwork"
        case .savedAppState:
            return "Window positions and app states for resume"
        case .fontCaches:
            return "Font rendering caches for faster text display"
        case .siriDictation:
            return "Speech recognition models and Siri data"
        case .languageResources:
            return "Localization files and translation data"
        case .systemTempFolders:
            return "Per-user temporary folders managed by macOS"
        }
    }

    /// Detailed explanation shown when user wants more info
    var detailedInfo: (whatItIs: String, examples: [String], ifDeleted: String, recommendation: String) {
        switch self {
        case .timeMachineSnapshots:
            return (
                whatItIs: "Time Machine creates hourly snapshots of your entire disk. These are point-in-time copies that let you restore files or your whole system. They're stored locally on your drive even when your backup drive isn't connected.",
                examples: ["Snapshot from 2 hours ago", "Snapshot from yesterday", "Snapshot from last week"],
                ifDeleted: "You won't be able to restore files from these specific points in time. Your external Time Machine backups are NOT affected.",
                recommendation: "Safe to delete. macOS will create new snapshots automatically. Delete older ones first."
            )
        case .userCaches:
            return (
                whatItIs: "Caches are temporary files apps create to speed up loading. For example, Spotify caches songs for offline play, Safari caches website images so pages load faster.",
                examples: ["Spotify offline songs", "Safari website images", "App Store downloads", "Slack cached messages"],
                ifDeleted: "Apps will run slightly slower temporarily while they rebuild their caches. No data is lost - apps will re-download what they need.",
                recommendation: "Safe to delete. This is the easiest way to free up space with zero risk."
            )
        case .systemCaches:
            return (
                whatItIs: "Similar to user caches, but created by macOS itself and system services. Includes font caches, Quick Look previews, and system update files.",
                examples: ["Font caches", "Quick Look thumbnails", "System update downloads", "Printer driver caches"],
                ifDeleted: "macOS will rebuild these automatically. First launch after deletion may be slightly slower.",
                recommendation: "Safe to delete, but requires admin password. Good for freeing space."
            )
        case .logFiles:
            return (
                whatItIs: "Text files that record what your Mac and apps are doing. Useful for troubleshooting problems, but accumulate over time.",
                examples: ["system.log - macOS events", "wifi.log - network connections", "install.log - app installations", "crash reports"],
                ifDeleted: "You lose the ability to diagnose past issues. New logs will be created going forward. No apps will break.",
                recommendation: "Safe to delete unless you're actively debugging a problem."
            )
        case .tempFiles:
            return (
                whatItIs: "Files that apps create temporarily while working, like partial downloads or work-in-progress documents. Usually cleaned up automatically on reboot.",
                examples: ["Partial downloads", "App scratch files", "Installation temp files", "Print job spool files"],
                ifDeleted: "No effect in most cases. Rarely, an in-progress operation might fail.",
                recommendation: "Safe to delete. Restart your Mac first to let apps clean up properly."
            )
        case .developerData:
            return (
                whatItIs: "If you're a developer: Xcode build files (DerivedData), iOS Simulators, and package manager caches. If you're not a developer, this might be from apps you installed.",
                examples: ["Xcode DerivedData (rebuild cache)", "iOS Simulators (virtual iPhones)", "Homebrew packages", "npm/pip packages", "Docker images"],
                ifDeleted: "Your code is safe. Projects will take longer to build the first time. You may need to re-download dependencies.",
                recommendation: "Safe for DerivedData and caches. Be careful with Simulators if you need specific iOS versions."
            )
        case .iosBackups:
            return (
                whatItIs: "Complete backups of your iPhone or iPad made through Finder (or old iTunes). Includes apps, photos, messages, settings - everything on your device.",
                examples: ["iPhone backup from last sync", "Old iPad backup", "Multiple backups from same device"],
                ifDeleted: "You cannot restore your device from these backups. If your phone breaks, this data is gone forever.",
                recommendation: "CAUTION: Only delete if you have iCloud backups enabled, or you're sure you don't need them. Check in Finder first."
            )
        case .applicationSupport:
            return (
                whatItIs: "Where apps store their important data - not caches, but actual data you might care about. Databases, saved games, app settings, license files.",
                examples: ["Photoshop presets", "Game save files", "App licenses", "Database files", "Custom templates"],
                ifDeleted: "Apps may lose settings, saved games, or important data. Some apps may need to be re-activated.",
                recommendation: "CAUTION: Only delete specific items you recognize and don't need. Don't delete entire folders blindly."
            )
        case .mailData:
            return (
                whatItIs: "Your email data if you use Apple Mail. Includes downloaded attachments, cached emails, and email database.",
                examples: ["Downloaded PDF attachments", "Cached email images", "Mail database", "Email search index"],
                ifDeleted: "Downloaded attachments will need to be re-downloaded. Your actual emails on the server are NOT deleted.",
                recommendation: "Moderate risk. Attachments can be re-downloaded, but it takes time. Don't delete if you have POP email accounts."
            )
        case .messagesData:
            return (
                whatItIs: "Photos, videos, documents, and stickers sent or received in iMessage/Messages app.",
                examples: ["Photos people sent you", "Videos from group chats", "Shared documents", "Sticker packs"],
                ifDeleted: "These files will be removed from your Mac. If you have Messages in iCloud, they'll be removed from all devices.",
                recommendation: "CAUTION: Save any important photos/videos first. These may not be recoverable."
            )
        case .spotlightIndex:
            return (
                whatItIs: "The search index that makes Spotlight (⌘+Space) fast. Without it, searching would scan every file each time.",
                examples: ["File content index", "App index", "Email index", "Contact index"],
                ifDeleted: "Spotlight will be slow/broken until it rebuilds (can take hours). Your files are not affected.",
                recommendation: "Only delete if Spotlight is broken. Rebuilding is slow and uses CPU."
            )
        case .browserData:
            return (
                whatItIs: "Data from Safari, Chrome, Firefox, Arc and other browsers. Includes cached websites, cookies (login sessions), history, and local storage.",
                examples: ["Cached images/CSS/JS", "Login cookies", "Browsing history", "Saved form data", "Local storage"],
                ifDeleted: "You'll be logged out of websites. Browsing history is lost. Websites load slower initially.",
                recommendation: "Moderate risk. You'll need to log in everywhere again. Consider using browser's built-in cleanup instead."
            )
        case .downloads:
            return (
                whatItIs: "Your Downloads folder. Files you've downloaded from the internet, email attachments you've saved, etc.",
                examples: ["Downloaded apps (.dmg)", "PDF documents", "Images from the web", "Email attachments"],
                ifDeleted: "These files are permanently deleted (or moved to Trash). You'd need to re-download them.",
                recommendation: "Review each file. Move important ones elsewhere first. Good place to find forgotten large files."
            )
        case .appContainers:
            return (
                whatItIs: "Sandboxed apps (from App Store) can't access your whole disk - they get their own private folder called a 'container'. This is where they store ALL their data.",
                examples: ["WhatsApp chat history", "Telegram downloads", "Notes app data", "Any App Store app's data"],
                ifDeleted: "The app loses ALL its data - settings, documents, history, everything. Like uninstalling and reinstalling.",
                recommendation: "CAUTION: Only delete containers for apps you no longer use. The app will start fresh like a new install."
            )
        case .virtualMemory:
            return (
                whatItIs: "When RAM is full, macOS moves inactive data to disk (swap). The sleep image lets your Mac resume after sleeping. These are managed automatically.",
                examples: ["swapfile0, swapfile1... (RAM overflow)", "sleepimage (hibernate data)"],
                ifDeleted: "You cannot and should not delete these. macOS manages them automatically.",
                recommendation: "View only. Restarting your Mac clears swap files naturally."
            )
        case .iCloudCache:
            return (
                whatItIs: "Local copies of files stored in iCloud Drive, plus sync metadata and CloudKit caches. macOS keeps copies of recently accessed files for faster access.",
                examples: ["iCloud Drive file cache", "CloudKit sync data", "iCloud Photos thumbnails", "iCloud Documents cache"],
                ifDeleted: "Files will need to be re-downloaded from iCloud when you access them. Original files in iCloud are NOT deleted.",
                recommendation: "Safe to delete caches. Files will re-download as needed. Good for freeing space if you have fast internet."
            )
        case .photosCache:
            return (
                whatItIs: "Photos app stores thumbnails, face recognition data, scene analysis, and optimized versions of your photos locally. This can grow very large.",
                examples: ["Thumbnail cache", "Face recognition data", "Scene analysis", "Optimized previews", "Smart album data"],
                ifDeleted: "Photos will regenerate thumbnails (can take hours). Face recognition may need to re-analyze your library.",
                recommendation: "Moderate risk. Regeneration is slow but no photos are lost. Only delete if you need significant space."
            )
        case .musicPodcastCache:
            return (
                whatItIs: "Downloaded songs from Apple Music, podcast episodes, and album artwork. Also includes the Music/Podcasts app database and playback data.",
                examples: ["Downloaded Apple Music songs", "Podcast episodes", "Album artwork", "Playback history", "Library database"],
                ifDeleted: "Downloaded music/podcasts will need to be re-downloaded. Your playlists and library in iCloud are NOT affected.",
                recommendation: "Safe to delete downloaded content. You can always re-download. Check what's downloaded first in the Music app."
            )
        case .savedAppState:
            return (
                whatItIs: "macOS saves the state of apps when you quit so they can restore windows and documents. This includes window positions, scroll positions, and open documents.",
                examples: ["Safari open tabs", "TextEdit open documents", "Finder window positions", "App window states"],
                ifDeleted: "Apps will start fresh without remembering their previous state. No documents are lost, just the 'resume' state.",
                recommendation: "Safe to delete. Apps will just start fresh like a new launch."
            )
        case .fontCaches:
            return (
                whatItIs: "Cached font rendering data that speeds up text display. macOS pre-renders common character combinations for faster display.",
                examples: ["Font activation cache", "Font rendering cache", "ATS font cache", "Font registry data"],
                ifDeleted: "Text may render slightly slower initially while caches rebuild. No fonts are deleted.",
                recommendation: "Safe to delete. Good to try if you're having font display issues."
            )
        case .siriDictation:
            return (
                whatItIs: "Speech recognition models for Siri and Dictation, voice profiles, and learned patterns. These can be quite large especially with 'Hey Siri' enabled.",
                examples: ["Speech recognition models", "Voice profile data", "Siri learning data", "Dictation cache"],
                ifDeleted: "Siri/Dictation may need to re-learn your voice and speech patterns. Features may be less accurate temporarily.",
                recommendation: "Moderate risk. Consider only if you don't use Siri/Dictation frequently."
            )
        case .languageResources:
            return (
                whatItIs: "Localization files for different languages, translation models for Safari and other apps, and spell-checking dictionaries. Many are in protected system locations.",
                examples: ["Unused language translations", "Translation models", "Spell-check dictionaries", "Localization files"],
                ifDeleted: "Cannot delete system language files. User-level translation caches are managed by macOS.",
                recommendation: "View only. These are mostly protected system files. Use System Settings to remove languages."
            )
        case .systemTempFolders:
            return (
                whatItIs: "/private/var/folders contains per-user temporary files, caches, and working directories. macOS creates unique folders here for each user. This is often the largest hidden System Data location.",
                examples: ["App temporary files", "Caches", "Quick Look previews", "Clipboard data", "Boot caches"],
                ifDeleted: "Active temporary operations may fail. Some apps may need to rebuild their state. Generally safe if no apps are running.",
                recommendation: "Safe to delete old/large items. Restart your Mac first to clear active temp files safely."
            )
        }
    }

    var basePaths: [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        switch self {
        case .timeMachineSnapshots:
            return [] // Handled via tmutil
        case .userCaches:
            return ["\(home)/Library/Caches"]
        case .systemCaches:
            return ["/Library/Caches"]
        case .logFiles:
            return ["\(home)/Library/Logs", "/var/log", "/Library/Logs"]
        case .tempFiles:
            return ["/private/tmp", "/tmp", "\(home)/Library/Caches/TemporaryItems"]
        case .developerData:
            return [
                "\(home)/Library/Developer/Xcode/DerivedData",
                "\(home)/Library/Developer/Xcode/iOS DeviceSupport",
                "\(home)/Library/Developer/Xcode/watchOS DeviceSupport",
                "\(home)/Library/Developer/Xcode/tvOS DeviceSupport",
                "\(home)/Library/Developer/Xcode/Archives",
                "\(home)/Library/Developer/CoreSimulator/Devices",
                "\(home)/Library/Developer/CoreSimulator/Caches",
                "\(home)/Library/Caches/Homebrew",
                "\(home)/.npm/_cacache",
                "\(home)/.cache/pip",
                "\(home)/.cache/yarn",
                "\(home)/Library/Caches/CocoaPods",
                "\(home)/Library/Caches/org.carthage.CarthageKit",
                "\(home)/.gradle/caches",
                "\(home)/.m2/repository",
                "\(home)/Library/Containers/com.docker.docker/Data",
                "\(home)/.docker"
            ]
        case .iosBackups:
            return ["\(home)/Library/Application Support/MobileSync/Backup"]
        case .applicationSupport:
            return ["\(home)/Library/Application Support"]
        case .mailData:
            return [
                "\(home)/Library/Mail",
                "\(home)/Library/Containers/com.apple.mail/Data/Library/Mail Downloads"
            ]
        case .messagesData:
            return [
                "\(home)/Library/Messages/Attachments",
                "\(home)/Library/Messages/StickerCache"
            ]
        case .spotlightIndex:
            return ["/.Spotlight-V100"]
        case .browserData:
            return [
                "\(home)/Library/Safari",
                "\(home)/Library/Caches/com.apple.Safari",
                "\(home)/Library/Application Support/Google/Chrome",
                "\(home)/Library/Caches/Google/Chrome",
                "\(home)/Library/Application Support/Firefox",
                "\(home)/Library/Caches/Firefox",
                "\(home)/Library/Application Support/Arc",
                "\(home)/Library/Caches/company.thebrowser.Browser"
            ]
        case .downloads:
            return ["\(home)/Downloads"]
        case .appContainers:
            return ["\(home)/Library/Containers", "\(home)/Library/Group Containers"]
        case .virtualMemory:
            return ["/private/var/vm"]
        case .iCloudCache:
            return [
                "\(home)/Library/Mobile Documents",
                "\(home)/Library/Application Support/CloudDocs",
                "\(home)/Library/Caches/CloudKit",
                "\(home)/Library/Caches/com.apple.cloudd",
                "\(home)/Library/Caches/com.apple.bird"
            ]
        case .photosCache:
            return [
                "\(home)/Pictures/Photos Library.photoslibrary/resources/cpl",
                "\(home)/Pictures/Photos Library.photoslibrary/resources/derivatives",
                "\(home)/Pictures/Photos Library.photoslibrary/resources/renders",
                "\(home)/Library/Caches/com.apple.Photos",
                "\(home)/Library/Caches/com.apple.photoanalysisd"
            ]
        case .musicPodcastCache:
            return [
                "\(home)/Library/Caches/com.apple.Music",
                "\(home)/Library/Caches/com.apple.AMPLibraryAgent",
                "\(home)/Library/Caches/com.apple.podcasts",
                "\(home)/Library/Group Containers/group.com.apple.podcasts",
                "\(home)/Music/Music/Media.localized/Apple Music",
                "\(home)/Library/Group Containers/group.com.apple.music"
            ]
        case .savedAppState:
            return ["\(home)/Library/Saved Application State"]
        case .fontCaches:
            return [
                "\(home)/Library/Caches/com.apple.FontRegistry",
                "/Library/Caches/com.apple.ATS",
                "/private/var/folders/font_caches",
                "\(home)/Library/Caches/ATS"
            ]
        case .siriDictation:
            return [
                "\(home)/Library/Assistant",
                "\(home)/Library/Caches/com.apple.Siri",
                "\(home)/Library/Caches/com.apple.SpeakSelection",
                "\(home)/Library/Dictation",
                "\(home)/Library/LanguageModeling"
            ]
        case .languageResources:
            return [
                "\(home)/Library/Translation",
                "\(home)/Library/Caches/com.apple.TranslationUIService",
                "/System/Library/LinguisticData"
            ]
        case .systemTempFolders:
            return [
                "/private/var/folders"
            ]
        }
    }

    var safetyLevel: SafetyLevel {
        switch self {
        case .timeMachineSnapshots, .userCaches, .logFiles, .tempFiles, .savedAppState, .fontCaches:
            return .safe
        case .systemCaches, .developerData, .browserData, .iCloudCache, .systemTempFolders:
            return .moderate
        case .downloads, .appContainers, .spotlightIndex, .photosCache, .musicPodcastCache, .siriDictation:
            return .caution
        case .iosBackups, .applicationSupport, .mailData, .messagesData, .languageResources:
            return .danger
        case .virtualMemory:
            return .readOnly
        }
    }

    var isDeletable: Bool {
        switch self {
        case .virtualMemory, .spotlightIndex, .languageResources:
            return false
        default:
            return true
        }
    }
}

enum SafetyLevel: String {
    case safe = "Safe"
    case moderate = "Moderate"
    case caution = "Caution"
    case danger = "Danger"
    case readOnly = "Read Only"

    var color: String {
        switch self {
        case .safe: return "green"
        case .moderate: return "yellow"
        case .caution: return "orange"
        case .danger: return "red"
        case .readOnly: return "gray"
        }
    }
}

struct StorageCategory: Identifiable {
    let id = UUID()
    let type: StorageCategoryType
    var items: [StorageItem]
    var isScanning: Bool = false
    var isExpanded: Bool = false
    var isSelected: Bool = false

    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }

    var selectedSize: Int64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case russian = "ru"
    case english = "en"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .russian: return "Русский"
        case .english: return "English"
        }
    }
}

@MainActor
public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()

    @Published public var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "FolderViewer.Language")
        }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "FolderViewer.Language"),
           let lang = AppLanguage(rawValue: saved) {
            self.language = lang
        } else {
            // Detect from system
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
            if preferred.hasPrefix("ru") || preferred.hasPrefix("be") || preferred.hasPrefix("uk") {
                self.language = .russian
            } else {
                self.language = .english
            }
        }
    }

    // MARK: - Strings

    public var appTitle: String {
        language == .russian ? "Folder Viewer — Просмотр размера папок" : "Folder Viewer — Folder Size Inspector"
    }

    public var openFolder: String {
        language == .russian ? "Открыть папку" : "Open Folder"
    }

    public var selectFolder: String {
        language == .russian ? "Выбрать папку" : "Select Folder"
    }

    public var selectFolderPrompt: String {
        language == .russian ? "Выбрать папку для просмотра" : "Select Folder to Inspect"
    }

    public var dropFolderHint: String {
        language == .russian ? "Перетащите папку сюда или выберите на диске" : "Drop folder here or choose from disk"
    }

    public var dropFolderRelease: String {
        language == .russian ? "Отпустите папку здесь" : "Drop folder here"
    }

    public var noFolderSelected: String {
        language == .russian ? "Папка не выбрана" : "No folder selected"
    }

    public var goUp: String {
        language == .russian ? "Перейти на уровень выше" : "Go to Parent Folder"
    }

    public var goBack: String {
        language == .russian ? "Назад (⌘[)" : "Back (⌘[)"
    }

    public var goForward: String {
        language == .russian ? "Вперёд (⌘])" : "Forward (⌘])"
    }

    public var history: String {
        language == .russian ? "История" : "History"
    }

    public var historyTitle: String {
        language == .russian ? "История путей" : "Path History"
    }

    public var recentFolders: String {
        language == .russian ? "История недавних папок" : "Recent Folders"
    }

    public var historyEmpty: String {
        language == .russian ? "История пуста" : "History is empty"
    }

    public var clearHistory: String {
        language == .russian ? "Очистить историю" : "Clear History"
    }

    public var removeFromHistory: String {
        language == .russian ? "Удалить из истории" : "Remove from history"
    }

    public var showFiles: String {
        language == .russian ? "Показывать файлы" : "Show files"
    }

    public var recalculateSize: String {
        language == .russian ? "Пересчитать размер" : "Recalculate Size"
    }

    public var recalculateSelected: String {
        language == .russian ? "Пересчитать выбранную папку" : "Recalculate Selected Folder"
    }

    public var recalculateVisible: String {
        language == .russian ? "Пересчитать все видимые папки" : "Recalculate All Visible Folders"
    }

    public var recalculateEntireCache: String {
        language == .russian ? "Пересчитать весь сохранённый кэш" : "Recalculate Entire Cache"
    }

    public var recalculateThisFolder: String {
        language == .russian ? "Пересчитать размер этой папки" : "Recalculate this folder"
    }

    public var filterPlaceholder: String {
        language == .russian ? "Фильтр..." : "Filter..."
    }

    public var sorting: String {
        language == .russian ? "Сортировка" : "Sort"
    }

    public var sortSizeDesc: String {
        language == .russian ? "Размер (по убыванию)" : "Size (Descending)"
    }

    public var sortSizeAsc: String {
        language == .russian ? "Размер (по возрастанию)" : "Size (Ascending)"
    }

    public var sortNameAsc: String {
        language == .russian ? "Имя (А - Я)" : "Name (A - Z)"
    }

    public var sortNameDesc: String {
        language == .russian ? "Имя (Я - А)" : "Name (Z - A)"
    }

    public var sortDateDesc: String {
        language == .russian ? "Дата (сначала новые)" : "Date (Newest first)"
    }

    // Column headers
    public var colName: String {
        language == .russian ? "Имя" : "Name"
    }

    public var colStatus: String {
        language == .russian ? "Статус" : "Status"
    }

    public var colItems: String {
        language == .russian ? "Объектов" : "Items"
    }

    public var colSize: String {
        language == .russian ? "Размер" : "Size"
    }

    public var colAction: String {
        language == .russian ? "Действие" : "Action"
    }

    // Status and row
    public var calculating: String {
        language == .russian ? "Подсчёт..." : "Calculating..."
    }

    public var cachedBadge: String {
        language == .russian ? "Кэш" : "Cached"
    }

    public func cachedTimeAgo(_ timeAgo: String) -> String {
        language == .russian ? "Кэш: \(timeAgo)" : "Cached: \(timeAgo)"
    }

    public func itemsCount(_ count: Int) -> String {
        language == .russian ? "\(count) эл." : "\(count) items"
    }

    public func loadedObjects(_ count: Int) -> String {
        language == .russian ? "Загружено объектов: \(count)" : "Loaded items: \(count)"
    }

    public func loadingFolder(_ name: String) -> String {
        language == .russian ? "Загрузка папки: \(name)..." : "Loading folder: \(name)..."
    }

    public func backgroundCalculation(_ count: Int) -> String {
        language == .russian ? "Фоновый подсчёт (\(count) папок)..." : "Background calculation (\(count) folders)..."
    }

    public func cacheStatsBottom(_ count: Int) -> String {
        language == .russian ? "Кэш: \(count) папок" : "Cache: \(count) folders"
    }

    public var showInFinder: String {
        language == .russian ? "Показать в Finder" : "Reveal in Finder"
    }

    public var openInTerminal: String {
        language == .russian ? "Открыть в Терминале" : "Open in Terminal"
    }

    public var copyPath: String {
        language == .russian ? "Скопировать путь" : "Copy Path"
    }

    public var cacheHelp: String {
        language == .russian ? "Размер сохранён в кэше. Нажмите пересчитать, чтобы обновить." : "Size is cached. Click recalculate to refresh."
    }

    // Cache Stats Sheet
    public var cacheSheetTitle: String {
        language == .russian ? "Управление кэшем размеров" : "Folder Size Cache Manager"
    }

    public var cacheSheetSubtitle: String {
        language == .russian ? "Размеры папок кэшируются на диске для мгновенного отображения." : "Folder sizes are cached on disk for instant opening."
    }

    public var cacheFoldersCount: String {
        language == .russian ? "Папок в кэше:" : "Folders in cache:"
    }

    public var cacheFileSizeOnDisk: String {
        language == .russian ? "Размер файла кэша на диске:" : "Cache file size on disk:"
    }

    public var recalculateAllCachedFolders: String {
        language == .russian ? "Пересчитать все закешированные папки" : "Recalculate all cached folders"
    }

    public var clearCache: String {
        language == .russian ? "Очистить кэш" : "Clear Cache"
    }

    public var close: String {
        language == .russian ? "Закрыть" : "Close"
    }

    public var languageLabel: String {
        language == .russian ? "Язык:" : "Language:"
    }
}


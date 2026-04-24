import SwiftUI
import SwiftData

enum AppRoute: Hashable {
    case history
    case results(NameComponents)
    case savedReport(UUID)
}

enum SheetRoute: String, Identifiable {
    case settings

    var id: String { rawValue }
}

struct ToastState: Identifiable {
    let id = UUID()
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path: [AppRoute] = []
    @Published var sheet: SheetRoute?

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard path.isEmpty == false else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}

@MainActor
final class AppSession: ObservableObject {
    @Published var preferences: UserPreferencesSnapshot = .default
    @Published var hasBootstrapped = false
    @Published var splashFinished = false
    @Published var historyCount = 0
    @Published var toast: ToastState?

    func bootstrap(context: ModelContext) async {
        guard hasBootstrapped == false else { return }
        do {
            preferences = try PersistenceService.shared.loadPreferences(context: context)
            historyCount = try PersistenceService.shared.historyCount(context: context)
        } catch {
            preferences = .default
            historyCount = 0
        }

        // First-launch language detection: if language is still "system",
        // try to match the device's preferred language to a supported language.
        if preferences.appLanguage == .system {
            if let detected = detectDeviceLanguage() {
                preferences.appLanguage = detected
                try? PersistenceService.shared.savePreferences(preferences, context: context)
            }
        }

        hasBootstrapped = true
    }

    private func detectDeviceLanguage() -> AppLanguage? {
        let preferredLanguages = Locale.preferredLanguages
        for identifier in preferredLanguages {
            if let matched = AppLanguage.from(localeIdentifier: identifier) {
                return matched
            }
        }
        return nil
    }

    func savePreferences(context: ModelContext) {
        do {
            try PersistenceService.shared.savePreferences(preferences, context: context)
        } catch {
            toast = ToastState(title: String(localized: "app.toast.saveSettingsFailed"), actionTitle: nil, action: nil)
        }
    }

    func refreshHistoryCount(context: ModelContext) {
        historyCount = (try? PersistenceService.shared.historyCount(context: context)) ?? historyCount
    }

    var preferredColorScheme: ColorScheme? {
        switch preferences.appearanceMode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var preferredLocale: Locale {
        if let identifier = preferences.appLanguage.localeIdentifier {
            return Locale(identifier: identifier)
        }
        return Locale.current
    }
}

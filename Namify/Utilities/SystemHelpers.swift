import SwiftUI
import UIKit

private final class BundleMarker {}

extension Bundle {
    static var namifyResources: Bundle {
        Bundle(for: BundleMarker.self)
    }
}

enum AppLocalization {
    private static var selectedLanguage: AppLanguage = .system

    static func setLanguage(_ language: AppLanguage) {
        selectedLanguage = language.supportedOrSystem
    }

    static func string(_ key: String, table: String? = nil) -> String {
        let baseBundle = Bundle.namifyResources

        if let identifier = selectedLanguage.localeIdentifier,
           let path = baseBundle.path(forResource: identifier, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let localized = bundle.localizedString(forKey: key, value: nil, table: table)
            if localized != key {
                return localized
            }
        }

        if selectedLanguage != .system,
           let path = baseBundle.path(forResource: AppLanguage.english.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let localized = bundle.localizedString(forKey: key, value: nil, table: table)
            if localized != key {
                return localized
            }
        }

        return baseBundle.localizedString(forKey: key, value: nil, table: table)
    }
}

func L(_ key: String) -> String {
    AppLocalization.string(key)
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension Date {
    var namifyRelativeLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return L("time.today") }
        if calendar.isDateInYesterday(self) { return L("time.yesterday") }
        let days = calendar.dateComponents([.day], from: self, to: .now).day ?? 0
        if days < 7 {
            return String(format: L("time.daysAgo"), days)
        }
        return formatted(.dateTime.month(.abbreviated).day())
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

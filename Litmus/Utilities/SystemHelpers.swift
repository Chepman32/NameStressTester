import SwiftUI
import UIKit

private final class BundleMarker {}

extension Bundle {
    static var litmusResources: Bundle {
        Bundle(for: BundleMarker.self)
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension Date {
    var litmusRelativeLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return String(localized: "time.today") }
        if calendar.isDateInYesterday(self) { return String(localized: "time.yesterday") }
        let days = calendar.dateComponents([.day], from: self, to: .now).day ?? 0
        if days < 7 {
            return String(format: String(localized: "time.daysAgo"), days)
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

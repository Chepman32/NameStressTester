import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var session: AppSession
    @State private var confirmClear = false
    @State private var shareItems: [Any] = []

    var body: some View {
        List {
            appearanceSection
            testsSection
            dataSection
            aboutSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: Binding(
            get: { shareItems.isEmpty == false },
            set: { if !$0 { shareItems = [] } }
        )) {
            ShareSheet(items: shareItems)
        }
    }

    private var appearanceSection: some View {
        Section(String(localized: "settings.appearance")) {
            VStack(alignment: .leading, spacing: LitmusSpacing.sm) {
                Text(String(localized: "settings.appearance.darkmode"))
                    .font(LitmusTypography.bodyMedium())
                    .foregroundStyle(Brand.textPrimary)
                LitmusSegmentedPicker(selection: session.preferences.appearanceMode) { mode in
                    session.preferences.appearanceMode = mode
                    session.savePreferences(context: modelContext)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var testsSection: some View {
        Section(String(localized: "settings.tests")) {
            Toggle(isOn: Binding(
                get: { session.preferences.includeMiddleName },
                set: {
                    session.preferences.includeMiddleName = $0
                    session.savePreferences(context: modelContext)
                }
            )) {
                Text(String(localized: "settings.tests.includeMiddle"))
            }
            .tint(Brand.accent)

            Toggle(isOn: Binding(
                get: { session.preferences.strictMode },
                set: {
                    session.preferences.strictMode = $0
                    session.savePreferences(context: modelContext)
                }
            )) {
                Text(String(localized: "settings.tests.strict"))
            }
            .tint(Brand.accent)

            NavigationLink(String(localized: "settings.tests.reorder")) {
                TestOrderScreen(order: session.preferences.testOrder) { updated in
                    session.preferences.testOrder = updated
                    session.savePreferences(context: modelContext)
                }
            }
        }
    }

    private var dataSection: some View {
        Section(String(localized: "settings.data")) {
            Button {
                if confirmClear {
                    try? PersistenceService.shared.clearAllHistory(context: modelContext)
                    session.refreshHistoryCount(context: modelContext)
                    confirmClear = false
                    session.toast = ToastState(title: "History cleared", actionTitle: nil, action: nil)
                } else {
                    confirmClear = true
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(3))
                        confirmClear = false
                    }
                }
            } label: {
                Text(confirmClear ? String(localized: "settings.data.clearHistory.confirm") : String(localized: "settings.data.clearHistory"))
                    .foregroundStyle(Brand.fail)
            }

            Button {
                exportAll()
            } label: {
                Text(String(localized: "settings.data.export"))
            }
        }
    }

    private var aboutSection: some View {
        Section(String(localized: "settings.about")) {
            HStack {
                Text(String(localized: "settings.about.version"))
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(Brand.textSecondary)
            }
            NavigationLink(String(localized: "settings.about.about")) {
                StaticTextScreen(
                    title: "About Litmus",
                    bodyText: "Litmus is a fully offline iPhone and iPad utility that stress-tests a prospective name against rhyme exposure, initials, pronunciation friction, badge fit, namesake baggage, and monogram aesthetics."
                )
            }
            NavigationLink(String(localized: "settings.about.privacy")) {
                StaticTextScreen(
                    title: "Privacy Policy",
                    bodyText: "Litmus sends no data off-device, requests no network-backed account, and stores reports only in local SwiftData storage until the user deletes them."
                )
            }
        }
    }

    private func exportAll() {
        do {
            let data = try PersistenceService.shared.exportHistoryJSON(context: modelContext)
            let url = FileManager.default.temporaryDirectory.appending(path: "litmus-results.json")
            try data.write(to: url, options: .atomic)
            shareItems = [url]
        } catch {
            session.toast = ToastState(title: "Could not export history", actionTitle: nil, action: nil)
        }
    }
}

private struct TestOrderScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var order: [TestType]
    let onSave: ([TestType]) -> Void

    init(order: [TestType], onSave: @escaping ([TestType]) -> Void) {
        _order = State(initialValue: TestType.sanitizedOrder(order))
        self.onSave = onSave
    }

    var body: some View {
        List {
            ForEach(order, id: \.self) { type in
                HStack {
                    Text(String(localized: String.LocalizationValue(type.localizedNameKey)))
                    Spacer()
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(Brand.textTertiary)
                }
            }
            .onMove { source, destination in
                order.move(fromOffsets: source, toOffset: destination)
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Test Order")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    onSave(TestType.sanitizedOrder(order))
                    dismiss()
                }
            }
        }
    }
}

private struct StaticTextScreen: View {
    let title: String
    let bodyText: String

    var body: some View {
        ScrollView {
            Text(bodyText)
                .font(LitmusTypography.bodyMedium())
                .foregroundStyle(Brand.textPrimary)
                .padding(LitmusSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Brand.surface.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

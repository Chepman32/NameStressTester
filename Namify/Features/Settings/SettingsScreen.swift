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
        .scrollContentBackground(.hidden)
        .background(Brand.surface.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(Brand.accent)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "settings.button.done")) {
                    dismiss()
                }
                .font(NamifyTypography.bodyMedium().weight(.semibold))
                .foregroundStyle(Brand.accent)
            }
        }
        .sheet(isPresented: Binding(
            get: { shareItems.isEmpty == false },
            set: { if !$0 { shareItems = [] } }
        )) {
            ShareSheet(items: shareItems)
        }
    }

    private var appearanceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: NamifySpacing.sm) {
                Text(String(localized: "settings.appearance.darkmode"))
                    .font(NamifyTypography.bodyMedium())
                    .foregroundStyle(Brand.textPrimary)
                NamifySegmentedPicker(selection: session.preferences.appearanceMode) { mode in
                    session.preferences.appearanceMode = mode
                    session.savePreferences(context: modelContext)
                }
            }
            .padding(.vertical, 6)
            .listRowBackground(Brand.card)

            NavigationLink {
                LanguagePickerScreen(selection: session.preferences.appLanguage.supportedOrSystem) { language in
                    session.preferences.appLanguage = language
                    session.savePreferences(context: modelContext)
                }
            } label: {
                HStack {
                    Text(String(localized: "settings.appearance.language"))
                        .foregroundStyle(Brand.textPrimary)
                    Spacer()
                    Text(selectedLanguageLabel)
                        .foregroundStyle(Brand.textSecondary)
                }
            }
            .listRowBackground(Brand.card)
        } header: {
            sectionHeader(String(localized: "settings.appearance"))
        }
    }

    private var testsSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { session.preferences.includeMiddleName },
                set: {
                    session.preferences.includeMiddleName = $0
                    session.savePreferences(context: modelContext)
                }
            )) {
                Text(String(localized: "settings.tests.includeMiddle"))
                    .foregroundStyle(Brand.textPrimary)
            }
            .tint(Brand.accent)
            .listRowBackground(Brand.card)

            Toggle(isOn: Binding(
                get: { session.preferences.strictMode },
                set: {
                    session.preferences.strictMode = $0
                    session.savePreferences(context: modelContext)
                }
            )) {
                Text(String(localized: "settings.tests.strict"))
                    .foregroundStyle(Brand.textPrimary)
            }
            .tint(Brand.accent)
            .listRowBackground(Brand.card)

            NavigationLink(String(localized: "settings.tests.reorder")) {
                TestOrderScreen(order: session.preferences.testOrder) { updated in
                    session.preferences.testOrder = updated
                    session.savePreferences(context: modelContext)
                }
            }
            .foregroundStyle(Brand.textPrimary)
            .listRowBackground(Brand.card)
        } header: {
            sectionHeader(String(localized: "settings.tests"))
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                if confirmClear {
                    try? PersistenceService.shared.clearAllHistory(context: modelContext)
                    session.refreshHistoryCount(context: modelContext)
                    confirmClear = false
                    session.toast = ToastState(title: String(localized: "settings.toast.cleared"), actionTitle: nil, action: nil)
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
            .listRowBackground(Brand.card)

            Button {
                exportAll()
            } label: {
                Text(String(localized: "settings.data.export"))
                    .foregroundStyle(Brand.textPrimary)
            }
            .listRowBackground(Brand.card)
        } header: {
            sectionHeader(String(localized: "settings.data"))
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text(String(localized: "settings.about.version"))
                    .foregroundStyle(Brand.textPrimary)
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(Brand.textSecondary)
            }
            .listRowBackground(Brand.card)
            NavigationLink(String(localized: "settings.about.about")) {
                StaticTextScreen(
                    title: String(localized: "settings.about.title"),
                    bodyText: String(localized: "settings.about.body")
                )
            }
            .foregroundStyle(Brand.textPrimary)
            .listRowBackground(Brand.card)
            NavigationLink(String(localized: "settings.about.privacy")) {
                StaticTextScreen(
                    title: String(localized: "settings.privacy.title"),
                    bodyText: String(localized: "settings.privacy.body")
                )
            }
            .foregroundStyle(Brand.textPrimary)
            .listRowBackground(Brand.card)
        } header: {
            sectionHeader(String(localized: "settings.about"))
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(NamifyTypography.badge())
            .foregroundStyle(Brand.textTertiary)
            .textCase(.uppercase)
            .padding(.leading, NamifySpacing.xs)
    }

    private var selectedLanguageLabel: String {
        let language = session.preferences.appLanguage.supportedOrSystem
        return language == .system ? String(localized: "settings.language.system") : language.displayName
    }

    private func exportAll() {
        do {
            let data = try PersistenceService.shared.exportHistoryJSON(context: modelContext)
            let url = FileManager.default.temporaryDirectory.appending(path: "namify-results.json")
            try data.write(to: url, options: .atomic)
            shareItems = [url]
        } catch {
            session.toast = ToastState(title: String(localized: "settings.toast.exportFailed"), actionTitle: nil, action: nil)
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
                        .foregroundStyle(Brand.textPrimary)
                    Spacer()
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(Brand.textTertiary)
                }
            }
            .onMove { source, destination in
                order.move(fromOffsets: source, toOffset: destination)
            }
            .listRowBackground(Brand.card)
        }
        .environment(\.editMode, .constant(.active))
        .scrollContentBackground(.hidden)
        .background(Brand.surface.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.testOrder.title"))
        .toolbarBackground(Brand.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(Brand.accent)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "settings.button.done")) {
                    onSave(TestType.sanitizedOrder(order))
                    dismiss()
                }
            }
        }
    }
}

private struct LanguagePickerScreen: View {
    @Environment(\.dismiss) private var dismiss
    let selection: AppLanguage
    let onChange: (AppLanguage) -> Void

    var body: some View {
        List {
            ForEach(AppLanguage.selectableCases) { language in
                languageRow(language)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Brand.surface.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.language.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(Brand.accent)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "settings.button.done")) {
                    dismiss()
                }
                .font(NamifyTypography.bodyMedium().weight(.semibold))
                .foregroundStyle(Brand.accent)
            }
        }
    }

    private func languageRow(_ language: AppLanguage) -> some View {
        Button {
            onChange(language)
            dismiss()
        } label: {
            HStack {
                Text(language == .system
                     ? String(localized: "settings.language.system")
                     : language.displayName)
                    .foregroundStyle(Brand.textPrimary)
                Spacer()
                if selection == language {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Brand.accent)
                }
            }
        }
        .listRowBackground(Brand.card)
    }
}

private struct StaticTextScreen: View {
    let title: String
    let bodyText: String

    var body: some View {
        ScrollView {
            Text(bodyText)
                .font(NamifyTypography.bodyMedium())
                .foregroundStyle(Brand.textPrimary)
                .padding(NamifySpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Brand.surface.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(Brand.accent)
    }
}

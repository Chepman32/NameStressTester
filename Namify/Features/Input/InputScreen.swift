import SwiftUI

@MainActor
final class InputViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var middleName = ""
    @Published var lastName = ""
    @Published var suggestions: [String] = []
    @Published var isSubmitting = false

    var canSubmit: Bool {
        firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            && lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    func loadSuggestions(for language: AppLanguage) async {
        let resolvedLanguage = language.resolvedForSuggestions
        guard resolvedLanguage == .english else {
            suggestions = LocalizedNameSuggestions.names(for: resolvedLanguage)
            return
        }

        do {
            let frequency = try await OfflineDatasetStore.shared.frequencyDatabase()
            suggestions = Array(
                frequency.firstNames.sorted { $0.rank < $1.rank }.map(\.name).shuffled().prefix(12)
            )
        } catch {
            suggestions = LocalizedNameSuggestions.names(for: .english)
        }
    }

    var nameComponents: NameComponents {
        NameComponents(first: firstName, middle: middleName, last: lastName)
    }
}

enum LocalizedNameSuggestions {
    static func names(for language: AppLanguage) -> [String] {
        let pool = namesByLanguage[language.resolvedForSuggestions] ?? namesByLanguage[.english] ?? []
        return Array(pool.shuffled().prefix(12))
    }

    private static let namesByLanguage: [AppLanguage: [String]] = [
        .english: ["Olivia", "Liam", "Emma", "Noah", "Charlotte", "James", "Sophia", "Ava", "Eleanor", "Ada", "Atlas", "Sloane"],
        .arabic: ["آدم", "ليان", "عمر", "نور", "يوسف", "مريم", "سارة", "ليلى", "زيد", "جنى", "مالك", "رنا"],
        .chineseSimplified: ["子涵", "梓萱", "浩然", "一诺", "宇轩", "欣怡", "晨曦", "若曦", "明轩", "诗涵", "嘉怡", "俊杰"],
        .czech: ["Eliška", "Jan", "Anna", "Jakub", "Tereza", "Tomáš", "Adéla", "Matěj", "Sofie", "Ondřej", "Karolína", "Vojtěch"],
        .danish: ["Emma", "William", "Alma", "Noah", "Freja", "Oscar", "Ida", "Carl", "Clara", "Aksel", "Sofia", "Malthe"],
        .dutch: ["Emma", "Noah", "Julia", "Lucas", "Sophie", "Daan", "Mila", "Levi", "Tess", "Sem", "Nora", "Bram"],
        .finnish: ["Aino", "Elias", "Eevi", "Onni", "Sofia", "Eino", "Helmi", "Leo", "Aada", "Väinö", "Venla", "Noel"],
        .french: ["Emma", "Gabriel", "Louise", "Léo", "Jade", "Louis", "Alice", "Raphaël", "Chloé", "Arthur", "Lina", "Noah"],
        .german: ["Emilia", "Noah", "Mia", "Matteo", "Hannah", "Leon", "Emma", "Finn", "Sofia", "Elias", "Lina", "Paul"],
        .greek: ["Μαρία", "Γιώργος", "Ελένη", "Νίκος", "Σοφία", "Αλέξανδρος", "Άννα", "Δημήτρης", "Κατερίνα", "Κωνσταντίνος", "Ιωάννα", "Παναγιώτης"],
        .hebrew: ["נועה", "איתן", "תמר", "דניאל", "מאיה", "יונתן", "אביגיל", "אריאל", "יעל", "אורי", "שירה", "נועם"],
        .hindi: ["आरव", "आन्या", "विवान", "सिया", "अर्जुन", "अनिका", "कबीर", "ईशा", "रोहन", "मीरा", "आदित्य", "रिया"],
        .indonesian: ["Aisyah", "Rizky", "Putri", "Bima", "Nabila", "Dimas", "Siti", "Raka", "Alya", "Fajar", "Dewi", "Bagas"],
        .italian: ["Sofia", "Leonardo", "Giulia", "Francesco", "Aurora", "Alessandro", "Ginevra", "Lorenzo", "Alice", "Mattia", "Emma", "Tommaso"],
        .japanese: ["陽翔", "凛", "蓮", "陽葵", "湊", "結菜", "大和", "さくら", "悠真", "美咲", "蒼", "紬"],
        .korean: ["서준", "서연", "민준", "지우", "도윤", "하윤", "예준", "서아", "시우", "지아", "주원", "하린"],
        .malay: ["Aisyah", "Muhammad", "Nur", "Ahmad", "Siti", "Adam", "Sofia", "Danish", "Alya", "Irfan", "Hana", "Zafran"],
        .norwegian: ["Emma", "Jakob", "Nora", "Noah", "Sofie", "Emil", "Maja", "Oliver", "Ingrid", "Aksel", "Ella", "Lucas"],
        .polish: ["Zofia", "Antoni", "Zuzanna", "Jan", "Hanna", "Aleksander", "Maja", "Franciszek", "Julia", "Jakub", "Lena", "Stanisław"],
        .portugueseBrazil: ["Helena", "Miguel", "Alice", "Arthur", "Laura", "Heitor", "Maria", "Davi", "Sophia", "Bernardo", "Valentina", "Gabriel"],
        .russian: ["София", "Александр", "Анна", "Михаил", "Мария", "Артём", "Алиса", "Иван", "Виктория", "Дмитрий", "Ева", "Матвей"],
        .spanish: ["Lucía", "Mateo", "Sofía", "Martín", "Valentina", "Santiago", "María", "Leo", "Emma", "Daniel", "Camila", "Nicolás"],
        .swedish: ["Alice", "William", "Elsa", "Noah", "Vera", "Hugo", "Alma", "Elias", "Astrid", "Liam", "Maja", "Oliver"],
        .thai: ["น้องภีม", "น้องมิน", "น้องพิม", "น้องกันต์", "น้องออม", "น้องต้น", "น้องแพรว", "น้องภูมิ", "น้องฟ้า", "น้องตาล", "น้องนนท์", "น้องมายด์"],
        .turkish: ["Zeynep", "Yusuf", "Elif", "Eymen", "Defne", "Miraç", "Asya", "Ömer", "Azra", "Kerem", "Eylül", "Emir"],
        .ukrainian: ["Софія", "Артем", "Анна", "Максим", "Марія", "Дмитро", "Анастасія", "Богдан", "Вероніка", "Олександр", "Злата", "Матвій"],
        .vietnamese: ["An", "Minh", "Linh", "Huy", "Trang", "Nam", "Mai", "Phúc", "Ngọc", "Quân", "Thảo", "Duy"]
    ]
}

extension AppLanguage {
    var resolvedForSuggestions: AppLanguage {
        switch self {
        case .system:
            return AppLanguage.systemSuggestionLanguage ?? .english
        default:
            return self
        }
    }

    static var systemSuggestionLanguage: AppLanguage? {
        suggestionLanguage(
            from: Bundle.namifyResources.preferredLocalizations
                + Locale.preferredLanguages
                + [Locale.current.identifier]
        )
    }

    static func suggestionLanguage(from localeIdentifiers: [String]) -> AppLanguage? {
        for localeIdentifier in localeIdentifiers {
            if let language = suggestionLanguage(from: localeIdentifier) {
                return language
            }
        }

        return nil
    }

    private static func suggestionLanguage(from localeIdentifier: String) -> AppLanguage? {
        let normalized = localeIdentifier.replacingOccurrences(of: "_", with: "-")
        let lowercased = normalized.lowercased()

        if let exact = AppLanguage(rawValue: normalized), exact != .system {
            return exact
        }

        let languageCode = lowercased.split(separator: "-").first.map(String.init)

        switch languageCode {
        case "ms":
            return .malay
        default:
            return AppLanguage.from(localeIdentifier: localeIdentifier)
        }
    }
}

struct InputScreen: View {
    @StateObject private var viewModel = InputViewModel()
    @FocusState private var focus: Field?
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var session: AppSession

    private enum Field {
        case first
        case middle
        case last
    }

    var body: some View {
        ScrollView {
            VStack(spacing: NamifySpacing.xl) {
                header
                hero
                formFields
                suggestions
                cta
            }
            .padding(.horizontal, NamifySpacing.lg)
            .padding(.top, NamifySpacing.md)
            .padding(.bottom, NamifySpacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Brand.surface.ignoresSafeArea())
        .navigationBarHidden(true)
        .overlay(alignment: .bottomTrailing) {
            if focus != nil {
                keyboardDismissButton
                    .padding(.trailing, NamifySpacing.lg)
                    .padding(.bottom, NamifySpacing.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .highPriorityGesture(
            DragGesture()
                .onEnded { value in
                    guard abs(value.translation.height) < 80 else { return }
                    if value.translation.width < -120 {
                        coordinator.push(.history)
                    }
                }
        )
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
        .task(id: session.preferences.appLanguage) {
            await viewModel.loadSuggestions(for: session.preferences.appLanguage)
            session.refreshHistoryCount(context: modelContext)
        }
        .animation(NamifyMotion.micro, value: focus != nil)
    }

    private var header: some View {
        HStack {
            Button {
                coordinator.push(.history)
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 24))
                        .foregroundStyle(Brand.textSecondary)
                    if session.historyCount > 0 {
                        Circle()
                            .fill(Brand.accent)
                            .frame(width: 8, height: 8)
                            .offset(x: 3, y: -3)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()
            Text(L("input.header"))
                .font(NamifyTypography.subtitle())
                .foregroundStyle(Brand.primary)
            Spacer()

            Button {
                coordinator.sheet = .settings
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Brand.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var hero: some View {
        VStack(spacing: NamifySpacing.lg) {
            Circle()
                .fill(Brand.accent.opacity(0.10))
                .frame(width: 80, height: 80)
                .overlay {
                    Circle().stroke(Brand.accent.opacity(0.25), lineWidth: 1)
                }
                .overlay {
                    Image(systemName: "character.cursor.ibeam")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(Brand.accent)
                }
            VStack(spacing: NamifySpacing.sm) {
                Text(L("input.title"))
                    .font(NamifyTypography.title())
                    .foregroundStyle(Brand.textPrimary)
                Text(L("input.subtitle"))
                    .font(NamifyTypography.bodyMedium())
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, NamifySpacing.xl)
    }

    private var formFields: some View {
        VStack(spacing: NamifySpacing.md) {
            NamifyTextField(
                title: L("input.field.first"),
                text: $viewModel.firstName,
                isRequired: true,
                focused: focus == .first,
                submitLabel: .next
            )
            .focused($focus, equals: .first)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .onSubmit { focus = .middle }

            NamifyTextField(
                title: L("input.field.middle"),
                text: $viewModel.middleName,
                focused: focus == .middle,
                submitLabel: .next
            )
            .focused($focus, equals: .middle)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .onSubmit { focus = .last }

            NamifyTextField(
                title: L("input.field.last"),
                text: $viewModel.lastName,
                isRequired: true,
                focused: focus == .last,
                submitLabel: .go
            )
            .focused($focus, equals: .last)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .onSubmit {
                if viewModel.canSubmit { submit() }
            }
        }
    }

    private var suggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NamifySpacing.sm) {
                ForEach(viewModel.suggestions, id: \.self) { suggestion in
                    Button {
                        viewModel.firstName = suggestion
                        Haptics.selection()
                    } label: {
                        NamifyChip(title: suggestion)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white, location: 0.08),
                    .init(color: .white, location: 0.92),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private var cta: some View {
        VStack(spacing: NamifySpacing.md) {
            NamifyButton(
                title: L("input.cta"),
                style: .primary,
                isDisabled: viewModel.canSubmit == false,
                isLoading: viewModel.isSubmitting
            ) {
                submit()
            }
        }
    }

    private var keyboardDismissButton: some View {
        Button {
            focus = nil
            UIApplication.shared.endEditing()
        } label: {
            Label(L("input.keyboard.done"), systemImage: "keyboard.chevron.compact.down")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Brand.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Brand.card, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Brand.divider, lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func submit() {
        guard viewModel.canSubmit else { return }
        focus = nil
        UIApplication.shared.endEditing()
        viewModel.isSubmitting = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            coordinator.push(.results(viewModel.nameComponents))
            viewModel.isSubmitting = false
        }
    }
}

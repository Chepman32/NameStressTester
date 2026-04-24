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

    func loadSuggestions() async {
        do {
            let frequency = try await OfflineDatasetStore.shared.frequencyDatabase()
            suggestions = Array(
                frequency.firstNames.sorted { $0.rank < $1.rank }.map(\.name).shuffled().prefix(12)
            )
        } catch {
            suggestions = ["Ada", "Cleo", "Liam", "Emma", "Atlas", "Sloane", "Niamh", "James"]
        }
    }

    var nameComponents: NameComponents {
        NameComponents(first: firstName, middle: middleName, last: lastName)
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
        .task {
            await viewModel.loadSuggestions()
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
            Text(String(localized: "input.header"))
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
                Text(String(localized: "input.title"))
                    .font(NamifyTypography.title())
                    .foregroundStyle(Brand.textPrimary)
                Text(String(localized: "input.subtitle"))
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
                title: String(localized: "input.field.first"),
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
                title: String(localized: "input.field.middle"),
                text: $viewModel.middleName,
                focused: focus == .middle,
                submitLabel: .next
            )
            .focused($focus, equals: .middle)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .onSubmit { focus = .last }

            NamifyTextField(
                title: String(localized: "input.field.last"),
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
                title: String(localized: "input.cta"),
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
            Label(String(localized: "input.keyboard.done"), systemImage: "keyboard.chevron.compact.down")
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

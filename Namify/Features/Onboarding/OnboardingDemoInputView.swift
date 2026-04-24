import SwiftUI

struct OnboardingDemoInputView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @State private var firstName = ""
    @State private var middleName = ""
    @State private var lastName = ""
    @FocusState private var focus: Field?

    private enum Field {
        case first, middle, last
    }

    private var canSubmit: Bool {
        firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            && lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var body: some View {
        ScrollView {
            VStack(spacing: NamifySpacing.xl) {
                VStack(spacing: NamifySpacing.sm) {
                    Text(L("onboarding.demo.headline"))
                        .font(NamifyTypography.title())
                        .foregroundStyle(Brand.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(L("onboarding.demo.subheadline"))
                        .font(NamifyTypography.bodyMedium())
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: NamifySpacing.md) {
                    NamifyTextField(
                        title: L("input.field.first"),
                        text: $firstName,
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
                        text: $middleName,
                        focused: focus == .middle,
                        submitLabel: .next
                    )
                    .focused($focus, equals: .middle)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onSubmit { focus = .last }

                    NamifyTextField(
                        title: L("input.field.last"),
                        text: $lastName,
                        isRequired: true,
                        focused: focus == .last,
                        submitLabel: .go
                    )
                    .focused($focus, equals: .last)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onSubmit {
                        if canSubmit { submit() }
                    }
                }

                Spacer(minLength: NamifySpacing.xl)
            }
            .padding(.horizontal, NamifySpacing.lg)
            .padding(.top, NamifySpacing.md)
            .padding(.bottom, NamifySpacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Brand.surface.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            NamifyButton(
                title: L("onboarding.demo.cta"),
                isDisabled: !canSubmit,
                isLoading: viewModel.isRunningDemo
            ) {
                submit()
            }
            .padding(.horizontal, NamifySpacing.lg)
            .padding(.bottom, NamifySpacing.lg)
        }
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
    }

    private func submit() {
        guard canSubmit else { return }
        focus = nil
        UIApplication.shared.endEditing()
        let name = NameComponents(first: firstName, middle: middleName, last: lastName)
        viewModel.demoName = name
        viewModel.isRunningDemo = true
        Task { @MainActor in
            if let summary = await viewModel.runDemo(name: name) {
                viewModel.demoSummary = summary
                viewModel.isRunningDemo = false
                viewModel.advance()
            } else {
                viewModel.isRunningDemo = false
            }
        }
    }
}

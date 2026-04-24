import SwiftUI

struct OnboardingPreferencesView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    private var testOptions: [(type: TestType, emoji: String, description: String)] {
        [
            (.rhyme, "🎵", L("onboarding.prefs.rhyme")),
            (.initials, "🔤", L("onboarding.prefs.initials")),
            (.pronunciation, "🗣️", L("onboarding.prefs.pronunciation")),
            (.nameTag, "🏷️", L("onboarding.prefs.nametag")),
            (.namesake, "📖", L("onboarding.prefs.namesake")),
            (.monogram, "✒️", L("onboarding.prefs.monogram")),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: NamifySpacing.xl) {
                    VStack(spacing: NamifySpacing.sm) {
                        Text(L("onboarding.prefs.headline"))
                            .font(NamifyTypography.title())
                            .foregroundStyle(Brand.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(L("onboarding.prefs.subheadline"))
                            .font(NamifyTypography.bodyMedium())
                            .foregroundStyle(Brand.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NamifySpacing.md) {
                        ForEach(testOptions, id: \.type) { option in
                            TestOptionCell(
                                option: option,
                                isSelected: viewModel.selectedTests.contains(option.type)
                            ) {
                                withAnimation(NamifyMotion.snappy) {
                                    if viewModel.selectedTests.contains(option.type) {
                                        if viewModel.selectedTests.count > 1 {
                                            viewModel.selectedTests.remove(option.type)
                                        }
                                    } else {
                                        viewModel.selectedTests.insert(option.type)
                                        Haptics.selection()
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: NamifySpacing.xl)
                }
                .padding(.horizontal, NamifySpacing.lg)
                .padding(.top, NamifySpacing.md)
                .padding(.bottom, NamifySpacing.xxxl)
            }

            NamifyButton(
                title: L("onboarding.prefs.cta"),
                isDisabled: viewModel.selectedTests.isEmpty
            ) {
                Haptics.impact(.medium)
                viewModel.advance()
            }
            .padding(.horizontal, NamifySpacing.lg)
            .padding(.bottom, NamifySpacing.lg)
        }
        .background(Brand.surface.ignoresSafeArea())
    }
}

private struct TestOptionCell: View {
    let option: (type: TestType, emoji: String, description: String)
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: NamifySpacing.sm) {
                HStack {
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Brand.accent)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Circle()
                            .stroke(Brand.divider, lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                    }
                }

                Text(option.emoji)
                    .font(.system(size: 32))

                Text(option.type.displayName)
                    .font(NamifyTypography.bodyMedium().weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(option.description)
                    .font(NamifyTypography.bodySmall())
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(NamifySpacing.md)
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Brand.accent.opacity(0.08) : Brand.card, in: RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
                    .stroke(isSelected ? Brand.accent : Brand.divider, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private extension TestType {
    var displayName: String {
        L(self.localizedNameKey)
    }
}

import SwiftUI

struct OnboardingPreferencesView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    private let testOptions: [(type: TestType, emoji: String, description: String)] = [
        (.rhyme, "🎵", "Detect risky rhymes"),
        (.initials, "🔤", "Check for bad initials"),
        (.pronunciation, "🗣️", "Score speaking difficulty"),
        (.nameTag, "🏷️", "Preview badge fit"),
        (.namesake, "📖", "Check famous namesakes"),
        (.monogram, "✒️", "Rate monogram style"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: LitmusSpacing.xl) {
                    VStack(spacing: LitmusSpacing.sm) {
                        Text("onboarding.prefs.headline")
                            .font(LitmusTypography.title())
                            .foregroundStyle(Brand.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("onboarding.prefs.subheadline")
                            .font(LitmusTypography.bodyMedium())
                            .foregroundStyle(Brand.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LitmusSpacing.md) {
                        ForEach(testOptions, id: \.type) { option in
                            TestOptionCell(
                                option: option,
                                isSelected: viewModel.selectedTests.contains(option.type)
                            ) {
                                withAnimation(LitmusMotion.snappy) {
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

                    Spacer(minLength: LitmusSpacing.xl)
                }
                .padding(.horizontal, LitmusSpacing.lg)
                .padding(.top, LitmusSpacing.md)
                .padding(.bottom, LitmusSpacing.xxxl)
            }

            LitmusButton(
                title: String(localized: "onboarding.prefs.cta"),
                isDisabled: viewModel.selectedTests.isEmpty
            ) {
                Haptics.impact(.medium)
                viewModel.advance()
            }
            .padding(.horizontal, LitmusSpacing.lg)
            .padding(.bottom, LitmusSpacing.lg)
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
            VStack(spacing: LitmusSpacing.sm) {
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
                    .font(LitmusTypography.bodyMedium().weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(option.description)
                    .font(LitmusTypography.bodySmall())
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(LitmusSpacing.md)
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Brand.accent.opacity(0.08) : Brand.card, in: RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous)
                    .stroke(isSelected ? Brand.accent : Brand.divider, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private extension TestType {
    var displayName: String {
        String(localized: String.LocalizationValue(self.localizedNameKey))
    }
}

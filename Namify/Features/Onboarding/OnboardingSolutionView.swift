import SwiftUI

struct OnboardingSolutionView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    private var mappings: [SolutionMapping] {
        viewModel.solutionMappings()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: NamifySpacing.xl) {
                    VStack(spacing: NamifySpacing.sm) {
                        Text("onboarding.solution.headline")
                            .font(NamifyTypography.title())
                            .foregroundStyle(Brand.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("onboarding.solution.subheadline")
                            .font(NamifyTypography.bodyMedium())
                            .foregroundStyle(Brand.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: NamifySpacing.md) {
                        ForEach(mappings) { mapping in
                            SolutionRow(mapping: mapping)
                        }
                    }

                    Spacer(minLength: NamifySpacing.xl)
                }
                .padding(.horizontal, NamifySpacing.lg)
                .padding(.top, NamifySpacing.md)
                .padding(.bottom, NamifySpacing.xxxl)
            }

            NamifyButton(title: String(localized: "onboarding.solution.cta")) {
                Haptics.impact(.medium)
                viewModel.advance()
            }
            .padding(.horizontal, NamifySpacing.lg)
            .padding(.bottom, NamifySpacing.lg)
        }
        .background(Brand.surface.ignoresSafeArea())
    }
}

private struct SolutionRow: View {
    let mapping: SolutionMapping

    var body: some View {
        HStack(alignment: .top, spacing: NamifySpacing.md) {
            Image(systemName: mapping.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(mapping.color)
                .frame(width: 44, height: 44)
                .background(mapping.color.opacity(0.12), in: RoundedRectangle(cornerRadius: NamifyRadius.small, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(mapping.painPoint)
                    .font(NamifyTypography.bodySmall())
                    .foregroundStyle(Brand.textTertiary)
                    .strikethrough()

                Text(mapping.solution)
                    .font(NamifyTypography.bodyMedium())
                    .foregroundStyle(Brand.textPrimary)
                    .lineSpacing(3)
            }

            Spacer()
        }
        .padding(NamifySpacing.md)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
                .stroke(Brand.divider, lineWidth: 1)
        }
    }
}

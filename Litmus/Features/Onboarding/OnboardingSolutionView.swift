import SwiftUI

struct OnboardingSolutionView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    private var mappings: [SolutionMapping] {
        viewModel.solutionMappings()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: LitmusSpacing.xl) {
                    VStack(spacing: LitmusSpacing.sm) {
                        Text("onboarding.solution.headline")
                            .font(LitmusTypography.title())
                            .foregroundStyle(Brand.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("onboarding.solution.subheadline")
                            .font(LitmusTypography.bodyMedium())
                            .foregroundStyle(Brand.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: LitmusSpacing.md) {
                        ForEach(mappings) { mapping in
                            SolutionRow(mapping: mapping)
                        }
                    }

                    Spacer(minLength: LitmusSpacing.xl)
                }
                .padding(.horizontal, LitmusSpacing.lg)
                .padding(.top, LitmusSpacing.md)
                .padding(.bottom, LitmusSpacing.xxxl)
            }

            LitmusButton(title: String(localized: "onboarding.solution.cta")) {
                Haptics.impact(.medium)
                viewModel.advance()
            }
            .padding(.horizontal, LitmusSpacing.lg)
            .padding(.bottom, LitmusSpacing.lg)
        }
        .background(Brand.surface.ignoresSafeArea())
    }
}

private struct SolutionRow: View {
    let mapping: SolutionMapping

    var body: some View {
        HStack(alignment: .top, spacing: LitmusSpacing.md) {
            Image(systemName: mapping.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(mapping.color)
                .frame(width: 44, height: 44)
                .background(mapping.color.opacity(0.12), in: RoundedRectangle(cornerRadius: LitmusRadius.small, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(mapping.painPoint)
                    .font(LitmusTypography.bodySmall())
                    .foregroundStyle(Brand.textTertiary)
                    .strikethrough()

                Text(mapping.solution)
                    .font(LitmusTypography.bodyMedium())
                    .foregroundStyle(Brand.textPrimary)
                    .lineSpacing(3)
            }

            Spacer()
        }
        .padding(LitmusSpacing.md)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous)
                .stroke(Brand.divider, lineWidth: 1)
        }
    }
}

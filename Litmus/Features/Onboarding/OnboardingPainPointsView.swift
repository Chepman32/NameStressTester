import SwiftUI

struct OnboardingPainPointsView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: LitmusSpacing.xl) {
                VStack(spacing: LitmusSpacing.sm) {
                    Text("onboarding.pain.headline")
                        .font(LitmusTypography.title())
                        .foregroundStyle(Brand.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("onboarding.pain.subheadline")
                        .font(LitmusTypography.bodyMedium())
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: LitmusSpacing.sm) {
                    ForEach(viewModel.painPoints) { point in
                        PainPointRow(
                            point: point,
                            isSelected: viewModel.selectedPainPoints.contains(point)
                        ) {
                            withAnimation(LitmusMotion.snappy) {
                                if viewModel.selectedPainPoints.contains(point) {
                                    viewModel.selectedPainPoints.remove(point)
                                } else {
                                    viewModel.selectedPainPoints.insert(point)
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
        .background(Brand.surface.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            LitmusButton(
                title: String(localized: "onboarding.continue"),
                isDisabled: viewModel.selectedPainPoints.isEmpty
            ) {
                Haptics.impact(.medium)
                viewModel.advance()
            }
            .padding(.horizontal, LitmusSpacing.lg)
            .padding(.bottom, LitmusSpacing.lg)
        }
    }
}

private struct PainPointRow: View {
    let point: OnboardingPainPoint
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LitmusSpacing.md) {
                Text(point.emoji)
                    .font(.system(size: 24))

                Text(point.title)
                    .font(LitmusTypography.bodyLarge())
                    .foregroundStyle(Brand.textPrimary)

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isSelected ? Brand.accent : Brand.divider, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Brand.accent)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, LitmusSpacing.md)
            .padding(.vertical, 14)
            .background(isSelected ? Brand.accent.opacity(0.06) : Brand.card, in: RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous)
                    .stroke(isSelected ? Brand.accent.opacity(0.3) : Brand.divider, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

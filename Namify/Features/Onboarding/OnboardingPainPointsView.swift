import SwiftUI

struct OnboardingPainPointsView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: NamifySpacing.xl) {
                    VStack(spacing: NamifySpacing.sm) {
                        Text(L("onboarding.pain.headline"))
                            .font(NamifyTypography.title())
                            .foregroundStyle(Brand.textPrimary)
                            .multilineTextAlignment(.center)

                        if viewModel.selectedPainPoints.isEmpty {
                            Text(L("onboarding.pain.subheadline"))
                                .font(NamifyTypography.bodyMedium())
                                .foregroundStyle(Brand.textSecondary)
                                .multilineTextAlignment(.center)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.78), value: viewModel.selectedPainPoints.isEmpty)

                    VStack(spacing: NamifySpacing.sm) {
                        ForEach(viewModel.painPoints) { point in
                            PainPointRow(
                                point: point,
                                isSelected: viewModel.selectedPainPoints.contains(point)
                            ) {
                                withAnimation(NamifyMotion.snappy) {
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

                    Spacer(minLength: NamifySpacing.xl)
                }
                .padding(.horizontal, NamifySpacing.lg)
                .padding(.top, NamifySpacing.md)
            }

            NamifyButton(
                title: L("onboarding.continue"),
                isDisabled: viewModel.selectedPainPoints.isEmpty
            ) {
                Haptics.impact(.medium)
                viewModel.advance()
            }
            .padding(.horizontal, NamifySpacing.lg)
            .padding(.vertical, NamifySpacing.lg)
        }
        .background(Brand.surface.ignoresSafeArea())
    }
}

private struct PainPointRow: View {
    let point: OnboardingPainPoint
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: NamifySpacing.md) {
                Text(point.emoji)
                    .font(.system(size: 24))

                Text(point.title)
                    .font(NamifyTypography.bodyLarge())
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
            .padding(.horizontal, NamifySpacing.md)
            .padding(.vertical, 14)
            .background(isSelected ? Brand.accent.opacity(0.06) : Brand.card, in: RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
                    .stroke(isSelected ? Brand.accent.opacity(0.3) : Brand.divider, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

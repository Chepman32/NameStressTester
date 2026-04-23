import SwiftUI

struct OnboardingGoalView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: LitmusSpacing.xl) {
                    VStack(spacing: LitmusSpacing.sm) {
                        Text("onboarding.goal.headline")
                            .font(LitmusTypography.title())
                            .foregroundStyle(Brand.textPrimary)
                            .multilineTextAlignment(.center)

                        if viewModel.selectedGoal == nil {
                            Text("onboarding.goal.subheadline")
                                .font(LitmusTypography.bodyMedium())
                                .foregroundStyle(Brand.textSecondary)
                                .multilineTextAlignment(.center)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.78), value: viewModel.selectedGoal == nil)

                    VStack(spacing: LitmusSpacing.sm) {
                        ForEach(viewModel.goals) { goal in
                            GoalRow(
                                goal: goal,
                                isSelected: viewModel.selectedGoal?.id == goal.id
                            ) {
                                withAnimation(LitmusMotion.snappy) {
                                    if viewModel.selectedGoal?.id == goal.id {
                                        viewModel.selectedGoal = nil
                                    } else {
                                        viewModel.selectedGoal = goal
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
            }

            LitmusButton(
                title: String(localized: "onboarding.continue"),
                isDisabled: viewModel.selectedGoal == nil
            ) {
                Haptics.impact(.medium)
                viewModel.advance()
            }
            .padding(.horizontal, LitmusSpacing.lg)
            .padding(.vertical, LitmusSpacing.lg)
        }
        .background(Brand.surface.ignoresSafeArea())
    }
}

private struct GoalRow: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LitmusSpacing.md) {
                Text(goal.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(LitmusTypography.bodyLarge())
                        .foregroundStyle(Brand.textPrimary)
                    Text(goal.subtitle)
                        .font(LitmusTypography.bodySmall())
                        .foregroundStyle(Brand.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Brand.accent)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .stroke(Brand.divider, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, LitmusSpacing.md)
            .padding(.vertical, 14)
            .background(isSelected ? Brand.accent.opacity(0.08) : Brand.card, in: RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous)
                    .stroke(isSelected ? Brand.accent : Brand.divider, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

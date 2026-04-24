import SwiftUI

struct OnboardingGoalView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: NamifySpacing.xl) {
                    VStack(spacing: NamifySpacing.sm) {
                        Text("onboarding.goal.headline")
                            .font(NamifyTypography.title())
                            .foregroundStyle(Brand.textPrimary)
                            .multilineTextAlignment(.center)

                        if viewModel.selectedGoal == nil {
                            Text("onboarding.goal.subheadline")
                                .font(NamifyTypography.bodyMedium())
                                .foregroundStyle(Brand.textSecondary)
                                .multilineTextAlignment(.center)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.78), value: viewModel.selectedGoal == nil)

                    VStack(spacing: NamifySpacing.sm) {
                        ForEach(viewModel.goals) { goal in
                            GoalRow(
                                goal: goal,
                                isSelected: viewModel.selectedGoal?.id == goal.id
                            ) {
                                withAnimation(NamifyMotion.snappy) {
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

                    Spacer(minLength: NamifySpacing.xl)
                }
                .padding(.horizontal, NamifySpacing.lg)
                .padding(.top, NamifySpacing.md)
            }

            NamifyButton(
                title: String(localized: "onboarding.continue"),
                isDisabled: viewModel.selectedGoal == nil
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

private struct GoalRow: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: NamifySpacing.md) {
                Text(goal.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(NamifyTypography.bodyLarge())
                        .foregroundStyle(Brand.textPrimary)
                    Text(goal.subtitle)
                        .font(NamifyTypography.bodySmall())
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
            .padding(.horizontal, NamifySpacing.md)
            .padding(.vertical, 14)
            .background(isSelected ? Brand.accent.opacity(0.08) : Brand.card, in: RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
                    .stroke(isSelected ? Brand.accent : Brand.divider, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

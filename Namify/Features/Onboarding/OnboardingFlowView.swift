import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    let onComplete: () -> Void

    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var session: AppSession

    var body: some View {
        stepContent
            .environmentObject(viewModel)
            .safeAreaInset(edge: .top, spacing: 0) {
                topChrome
            }
            .background(Brand.surface.ignoresSafeArea())
    }

    @ViewBuilder
    private var stepContent: some View {
        let forward = viewModel.navigationDirection == .forward
        switch viewModel.currentStep {
        case .welcome:
            OnboardingWelcomeView()
                .transition(stepTransition(forward: forward))

        case .goal:
            OnboardingGoalView()
                .transition(stepTransition(forward: forward))

        case .painPoints:
            OnboardingPainPointsView()
                .transition(stepTransition(forward: forward))

        case .socialProof:
            OnboardingSocialProofView()
                .transition(stepTransition(forward: forward))

        case .solution:
            OnboardingSolutionView()
                .transition(stepTransition(forward: forward))

        case .preferences:
            OnboardingPreferencesView()
                .transition(stepTransition(forward: forward))

        case .processing:
            OnboardingProcessingView()
                .transition(.opacity)

        case .demoInput:
            OnboardingDemoInputView()
                .transition(stepTransition(forward: forward))

        case .demoResults:
            OnboardingDemoResultsView(onComplete: onComplete)
                .transition(stepTransition(forward: forward))
        }
    }

    private func stepTransition(forward: Bool) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading),
            removal: .move(edge: forward ? .leading : .trailing)
        )
    }

    private var topChrome: some View {
        HStack(spacing: NamifySpacing.md) {
            if viewModel.currentStep.canGoBack {
                Button {
                    Haptics.impact(.light)
                    viewModel.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Brand.accent)
                        .frame(width: 32, height: 32)
                        .background(Brand.accent.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("onboardingBackButton")
            }

            progressBar

            if viewModel.currentStep.canSkip {
                Button {
                    Haptics.impact(.light)
                    onComplete()
                } label: {
                    Text(L("onboarding.skip"))
                        .font(NamifyTypography.bodySmall().weight(.semibold))
                        .foregroundStyle(Brand.accent)
                        .namifyAdaptiveText(lineLimit: 1, minimumScaleFactor: 0.74)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Brand.accent.opacity(0.10), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("onboardingSkipButton")
            }
        }
            .padding(.horizontal, NamifySpacing.lg)
            .padding(.top, 10)
            .padding(.bottom, NamifySpacing.sm)
            .background {
                Brand.surface.ignoresSafeArea(edges: .top)
            }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Brand.divider)
                Capsule()
                    .fill(Brand.accent)
                    .frame(width: proxy.size.width * viewModel.progressFraction)
                    .animation(NamifyMotion.smooth, value: viewModel.progressFraction)
            }
        }
        .frame(height: 4)
    }

}

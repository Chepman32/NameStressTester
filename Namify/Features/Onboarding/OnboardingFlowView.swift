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
        switch viewModel.currentStep {
        case .welcome:
            OnboardingWelcomeView()
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

        case .goal:
            OnboardingGoalView()
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

        case .painPoints:
            OnboardingPainPointsView()
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

        case .socialProof:
            OnboardingSocialProofView()
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

        case .solution:
            OnboardingSolutionView()
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

        case .preferences:
            OnboardingPreferencesView()
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

        case .processing:
            OnboardingProcessingView()
                .transition(.opacity)

        case .demoInput:
            OnboardingDemoInputView()
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

        case .demoResults:
            OnboardingDemoResultsView(onComplete: onComplete)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
    }

    private var topChrome: some View {
        HStack(spacing: NamifySpacing.md) {
            progressBar

            if viewModel.currentStep.canSkip {
                Button {
                    Haptics.impact(.light)
                    onComplete()
                } label: {
                    Text(L("onboarding.skip"))
                        .font(NamifyTypography.bodySmall().weight(.semibold))
                        .foregroundStyle(Brand.accent)
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

import SwiftUI

struct OnboardingProcessingView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @State private var pulse = false
    @State private var rotate = false

    var body: some View {
        VStack(spacing: NamifySpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Brand.accent.opacity(0.08))
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulse ? 1.15 : 1.0)

                Circle()
                    .fill(Brand.accent.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulse ? 1.1 : 0.95)

                Image(systemName: "wand.and.stars")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(Brand.accent)
                    .rotationEffect(.degrees(rotate ? 10 : -10))
            }

            VStack(spacing: NamifySpacing.sm) {
                Text(L("onboarding.processing.headline"))
                    .font(NamifyTypography.subtitle())
                    .foregroundStyle(Brand.textPrimary)
                    .multilineTextAlignment(.center)

                Text(L("onboarding.processing.subheadline"))
                    .font(NamifyTypography.bodyMedium())
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, NamifySpacing.lg)
        .background(Brand.surface.ignoresSafeArea())
        .task {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                rotate = true
            }
            try? await Task.sleep(for: .seconds(2.5))
            viewModel.advance()
        }
    }
}

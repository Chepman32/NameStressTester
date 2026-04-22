import SwiftUI

struct OnboardingSwipeCardsView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @State private var currentIndex = 0
    @State private var offset: CGSize = .zero
    @State private var cardRotation: Double = 0

    private var remainingCards: [SwipeCardItem] {
        Array(viewModel.swipeCardItems.dropFirst(currentIndex))
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: LitmusSpacing.sm) {
                Text("onboarding.swipe.headline")
                    .font(LitmusTypography.title())
                    .foregroundStyle(Brand.textPrimary)
                    .multilineTextAlignment(.center)

                Text("onboarding.swipe.subheadline")
                    .font(LitmusTypography.bodyMedium())
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, LitmusSpacing.lg)
            .padding(.top, LitmusSpacing.md)

            Spacer()

            ZStack {
                ForEach(remainingCards.prefix(2).reversed(), id: \.id) { card in
                    let isTop = card.id == remainingCards.first?.id
                    SwipeCard(
                        text: card.text,
                        offset: isTop ? offset : .zero,
                        rotation: isTop ? cardRotation : 0
                    )
                    .scaleEffect(isTop ? 1.0 : 0.95)
                    .opacity(isTop ? 1.0 : 0.6)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard isTop else { return }
                                offset = value.translation
                                cardRotation = Double(value.translation.width / 20)
                            }
                            .onEnded { value in
                                guard isTop else { return }
                                let threshold: CGFloat = 100
                                if abs(value.translation.width) > threshold {
                                    let agreed = value.translation.width > 0
                                    viewModel.swipedCards[card] = agreed
                                    withAnimation(LitmusMotion.bouncy) {
                                        offset.width = value.translation.width > 0 ? 500 : -500
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        currentIndex += 1
                                        offset = .zero
                                        cardRotation = 0
                                        if currentIndex >= viewModel.swipeCardItems.count {
                                            viewModel.advance()
                                        }
                                    }
                                    Haptics.impact(.light)
                                } else {
                                    withAnimation(LitmusMotion.bouncy) {
                                        offset = .zero
                                        cardRotation = 0
                                    }
                                }
                            }
                    )
                }

                if remainingCards.isEmpty {
                    VStack(spacing: LitmusSpacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Brand.pass)
                        Text("onboarding.swipe.complete")
                            .font(LitmusTypography.subtitle())
                            .foregroundStyle(Brand.textPrimary)
                    }
                }
            }
            .frame(height: 340)
            .padding(.horizontal, LitmusSpacing.lg)

            Spacer()

            HStack(spacing: LitmusSpacing.xl) {
                swipeIndicator(icon: "xmark", label: String(localized: "onboarding.swipe.disagree"), color: Brand.fail)
                swipeIndicator(icon: "checkmark", label: String(localized: "onboarding.swipe.agree"), color: Brand.pass)
            }
            .padding(.bottom, LitmusSpacing.xl)
        }
        .background(Brand.surface.ignoresSafeArea())
    }

    private func swipeIndicator(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: LitmusSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(LitmusTypography.bodySmall())
                .foregroundStyle(Brand.textSecondary)
        }
    }
}

private struct SwipeCard: View {
    let text: String
    let offset: CGSize
    let rotation: Double

    var body: some View {
        Text(text)
            .font(LitmusTypography.subtitle())
            .foregroundStyle(Brand.textPrimary)
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .padding(LitmusSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: LitmusRadius.large, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LitmusRadius.large, style: .continuous)
                    .stroke(Brand.divider, lineWidth: 1)
            }
            .litmusCardShadow(LitmusShadow.floating)
            .offset(offset)
            .rotationEffect(.degrees(rotation))
    }
}

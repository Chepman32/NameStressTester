import SwiftUI

struct OnboardingSocialProofView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: LitmusSpacing.xl) {
                    VStack(spacing: LitmusSpacing.sm) {
                        Text("onboarding.social.headline")
                            .font(LitmusTypography.title())
                            .foregroundStyle(Brand.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("onboarding.social.subheadline")
                            .font(LitmusTypography.bodyMedium())
                            .foregroundStyle(Brand.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: LitmusSpacing.md) {
                        ForEach(viewModel.testimonials) { testimonial in
                            TestimonialCard(testimonial: testimonial)
                        }
                    }

                    Spacer(minLength: LitmusSpacing.xl)
                }
                .padding(.horizontal, LitmusSpacing.lg)
                .padding(.top, LitmusSpacing.md)
                .padding(.bottom, LitmusSpacing.xxxl)
            }

            LitmusButton(title: String(localized: "onboarding.continue")) {
                Haptics.impact(.medium)
                viewModel.advance()
            }
            .padding(.horizontal, LitmusSpacing.lg)
            .padding(.bottom, LitmusSpacing.lg)
        }
        .background(Brand.surface.ignoresSafeArea())
    }
}

private struct TestimonialCard: View {
    let testimonial: Testimonial

    var body: some View {
        VStack(alignment: .leading, spacing: LitmusSpacing.md) {
            HStack(spacing: LitmusSpacing.sm) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index < testimonial.rating ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundStyle(Brand.warn)
                }
            }

            Text(testimonial.text)
                .font(LitmusTypography.bodyMedium())
                .foregroundStyle(Brand.textPrimary)
                .lineSpacing(4)

            HStack(spacing: LitmusSpacing.sm) {
                Text(testimonial.name)
                    .font(LitmusTypography.bodySmall().weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)

                Text("·")
                    .foregroundStyle(Brand.textTertiary)

                Text(testimonial.tag)
                    .font(LitmusTypography.bodySmall())
                    .foregroundStyle(Brand.textSecondary)
            }
        }
        .padding(LitmusSpacing.md)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous)
                .stroke(Brand.divider, lineWidth: 1)
        }
    }
}

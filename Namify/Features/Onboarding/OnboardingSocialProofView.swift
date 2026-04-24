import SwiftUI

struct OnboardingSocialProofView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: NamifySpacing.xl) {
                    VStack(spacing: NamifySpacing.sm) {
                        Text(L("onboarding.social.headline"))
                            .font(NamifyTypography.title())
                            .foregroundStyle(Brand.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(L("onboarding.social.subheadline"))
                            .font(NamifyTypography.bodyMedium())
                            .foregroundStyle(Brand.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: NamifySpacing.md) {
                        ForEach(viewModel.testimonials) { testimonial in
                            TestimonialCard(testimonial: testimonial)
                        }
                    }

                    Spacer(minLength: NamifySpacing.xl)
                }
                .padding(.horizontal, NamifySpacing.lg)
                .padding(.top, NamifySpacing.md)
                .padding(.bottom, NamifySpacing.xxxl)
            }

            NamifyButton(title: L("onboarding.continue")) {
                Haptics.impact(.medium)
                viewModel.advance()
            }
            .padding(.horizontal, NamifySpacing.lg)
            .padding(.bottom, NamifySpacing.lg)
        }
        .background(Brand.surface.ignoresSafeArea())
    }
}

private struct TestimonialCard: View {
    let testimonial: Testimonial

    var body: some View {
        VStack(alignment: .leading, spacing: NamifySpacing.md) {
            HStack(spacing: NamifySpacing.sm) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index < testimonial.rating ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundStyle(Brand.warn)
                }
            }

            Text(testimonial.text)
                .font(NamifyTypography.bodyMedium())
                .foregroundStyle(Brand.textPrimary)
                .lineSpacing(4)

            HStack(spacing: NamifySpacing.sm) {
                Text(testimonial.name)
                    .font(NamifyTypography.bodySmall().weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)

                Text("·")
                    .foregroundStyle(Brand.textTertiary)

                Text(testimonial.tag)
                    .font(NamifyTypography.bodySmall())
                    .foregroundStyle(Brand.textSecondary)
            }
        }
        .padding(NamifySpacing.md)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
                .stroke(Brand.divider, lineWidth: 1)
        }
    }
}

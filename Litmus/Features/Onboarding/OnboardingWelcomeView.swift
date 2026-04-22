import SwiftUI

struct OnboardingWelcomeView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: LitmusSpacing.xl) {
                welcomeIcon

                VStack(spacing: LitmusSpacing.md) {
                    Text("onboarding.welcome.headline")
                        .font(LitmusTypography.title())
                        .foregroundStyle(Brand.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("onboarding.welcome.subheadline")
                        .font(LitmusTypography.bodyMedium())
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                previewCards
            }
            .padding(.horizontal, LitmusSpacing.lg)

            Spacer()

            VStack(spacing: LitmusSpacing.md) {
                LitmusButton(title: String(localized: "onboarding.welcome.cta")) {
                    Haptics.impact(.medium)
                    viewModel.advance()
                }

                Text("onboarding.welcome.footnote")
                    .font(LitmusTypography.bodySmall())
                    .foregroundStyle(Brand.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, LitmusSpacing.lg)
            .padding(.bottom, LitmusSpacing.xl)
        }
        .background(Brand.surface.ignoresSafeArea())
    }

    private var welcomeIcon: some View {
        ZStack {
            Circle()
                .fill(Brand.accent.opacity(0.10))
                .frame(width: 100, height: 100)
            Circle()
                .stroke(Brand.accent.opacity(0.25), lineWidth: 1)
                .frame(width: 100, height: 100)
            Image(systemName: "shield.checkered")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(Brand.accent)
        }
    }

    private var previewCards: some View {
        VStack(spacing: LitmusSpacing.sm) {
            previewRow(icon: "music.note.list", title: "Rhyme Vulnerability", color: Brand.rhyme)
            previewRow(icon: "textformat.abc", title: "Initials Check", color: Brand.initials)
            previewRow(icon: "waveform.and.person.filled", title: "Pronunciation", color: Brand.pronunciation)
        }
        .padding(.horizontal, LitmusSpacing.md)
    }

    private func previewRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: LitmusSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: LitmusRadius.small, style: .continuous))

            Text(title)
                .font(LitmusTypography.bodyMedium())
                .foregroundStyle(Brand.textPrimary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Brand.pass)
        }
        .padding(.horizontal, LitmusSpacing.md)
        .padding(.vertical, 12)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous)
                .stroke(Brand.divider, lineWidth: 1)
        }
    }
}

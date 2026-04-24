import SwiftUI

struct OnboardingWelcomeView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: NamifySpacing.xl) {
                welcomeIcon

                VStack(spacing: NamifySpacing.md) {
                    Text(L("onboarding.welcome.headline"))
                        .font(NamifyTypography.title())
                        .foregroundStyle(Brand.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(L("onboarding.welcome.subheadline"))
                        .font(NamifyTypography.bodyMedium())
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                previewCards
            }
            .padding(.horizontal, NamifySpacing.lg)

            Spacer()

            VStack(spacing: NamifySpacing.md) {
                NamifyButton(title: L("onboarding.welcome.cta")) {
                    Haptics.impact(.medium)
                    viewModel.advance()
                }

                Text(L("onboarding.welcome.footnote"))
                    .font(NamifyTypography.bodySmall())
                    .foregroundStyle(Brand.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, NamifySpacing.lg)
            .padding(.bottom, NamifySpacing.xl)
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
        VStack(spacing: NamifySpacing.sm) {
            previewRow(icon: "music.note.list", title: L("onboarding.welcome.preview.rhyme"), color: Brand.rhyme)
            previewRow(icon: "textformat.abc", title: L("onboarding.welcome.preview.initials"), color: Brand.initials)
            previewRow(icon: "waveform.and.person.filled", title: L("onboarding.welcome.preview.pronunciation"), color: Brand.pronunciation)
        }
        .padding(.horizontal, NamifySpacing.md)
    }

    private func previewRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: NamifySpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: NamifyRadius.small, style: .continuous))

            Text(title)
                .font(NamifyTypography.bodyMedium())
                .foregroundStyle(Brand.textPrimary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Brand.pass)
        }
        .padding(.horizontal, NamifySpacing.md)
        .padding(.vertical, 12)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
                .stroke(Brand.divider, lineWidth: 1)
        }
    }
}

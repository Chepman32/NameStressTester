import SwiftUI
import UIKit

@MainActor
enum ShareCardRenderer {
    static func renderReport(
        name: NameComponents,
        summary: NameRunSummary,
        colorScheme: ColorScheme?
    ) -> UIImage? {
        let view = ShareReportView(name: name, summary: summary)
            .environment(\.colorScheme, colorScheme ?? .light)
            .frame(width: 360, height: 640)
            .background(Brand.surface)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        renderer.proposedSize = .init(width: 360, height: 640)
        return renderer.uiImage
    }

    static func renderSingleTest(
        name: NameComponents,
        result: TestResult,
        colorScheme: ColorScheme?
    ) -> UIImage? {
        let view = ShareSingleTestView(name: name, result: result)
            .environment(\.colorScheme, colorScheme ?? .light)
            .frame(width: 360, height: 360)
            .background(Brand.surface)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        renderer.proposedSize = .init(width: 360, height: 360)
        return renderer.uiImage
    }
}

private struct ShareReportView: View {
    let name: NameComponents
    let summary: NameRunSummary

    var body: some View {
        VStack(spacing: LitmusSpacing.lg) {
            VStack(spacing: LitmusSpacing.sm) {
                Text("LITMUS")
                    .font(LitmusTypography.hero())
                    .foregroundStyle(Brand.textPrimary)
                Text(String(localized: "splash.tagline"))
                    .font(LitmusTypography.bodySmall())
                    .foregroundStyle(Brand.textSecondary)
                    .kerning(1.6)
            }

            Text(name.fullName)
                .font(LitmusTypography.title())
                .foregroundStyle(Brand.textPrimary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                ForEach(summary.results) { result in
                    HStack(spacing: LitmusSpacing.md) {
                        LitmusIconCircle(systemName: result.testType.systemImage, color: Brand.color(for: result.testType), size: 34)
                        Text(String(localized: String.LocalizationValue(result.testType.localizedNameKey)))
                            .font(LitmusTypography.bodySmall())
                            .foregroundStyle(Brand.textPrimary)
                        Spacer()
                        LitmusBadge(verdict: result.verdict, compact: true)
                    }
                    .padding(.horizontal, LitmusSpacing.md)
                    .padding(.vertical, 6)
                    .background(Brand.card, in: RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous))
                }
            }

            VStack(spacing: LitmusSpacing.sm) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(summary.overallVerdict == .failed ? Brand.fail : (summary.overallVerdict == .mixed ? Brand.warn : Brand.pass))
                Text(String(localized: String.LocalizationValue(summary.overallVerdict.headlineKey)))
                    .font(LitmusTypography.subtitle())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Brand.textPrimary)
                Text(String(format: String(localized: "results.score"), summary.passCount, summary.results.count))
                    .font(LitmusTypography.bodyMedium())
                    .foregroundStyle(Brand.textSecondary)
            }

            Spacer()

            VStack(spacing: 6) {
                Text(String(localized: "results.share.watermark"))
                    .font(LitmusTypography.bodySmall())
                    .foregroundStyle(Brand.textTertiary)
                Text(Date.now.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(LitmusTypography.bodySmall())
                    .foregroundStyle(Brand.textTertiary)
            }
        }
        .padding(LitmusSpacing.xl)
    }
}

private struct ShareSingleTestView: View {
    let name: NameComponents
    let result: TestResult

    var body: some View {
        VStack(alignment: .leading, spacing: LitmusSpacing.lg) {
            HStack {
                LitmusIconCircle(systemName: result.testType.systemImage, color: Brand.color(for: result.testType), size: 54)
                Spacer()
                LitmusBadge(verdict: result.verdict)
            }

            Text(name.fullName)
                .font(LitmusTypography.subtitle())
                .foregroundStyle(Brand.textSecondary)
            Text(String(localized: String.LocalizationValue(result.testType.localizedNameKey)))
                .font(LitmusTypography.title())
                .foregroundStyle(Brand.textPrimary)
            Text(result.summaryLine)
                .font(LitmusTypography.bodyLarge())
                .foregroundStyle(Brand.textPrimary)
            Text(result.detailText)
                .font(LitmusTypography.bodyMedium())
                .foregroundStyle(Brand.textSecondary)

            Spacer()

            Text("Tested with Litmus")
                .font(LitmusTypography.bodySmall())
                .foregroundStyle(Brand.textTertiary)
        }
        .padding(LitmusSpacing.xl)
    }
}

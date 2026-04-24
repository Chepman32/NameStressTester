import SwiftUI
import SwiftData

struct OnboardingDemoResultsView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.colorScheme) private var colorScheme
    @State private var expandedCards: Set<UUID> = []
    let onComplete: () -> Void

    var body: some View {
        Group {
            if let name = viewModel.demoName, let summary = viewModel.demoSummary {
                demoResultsContent(name: name, summary: summary)
            } else {
                ProgressView()
                    .tint(Brand.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Brand.surface.ignoresSafeArea())
            }
        }
    }

    private func demoResultsContent(name: NameComponents, summary: NameRunSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NamifySpacing.lg) {
                heroSection(name: name, summary: summary)
                cardsSection(name: name, results: summary.results)
                verdictSection(summary: summary)
                completionCTA
            }
            .padding(.horizontal, 20)
            .padding(.bottom, NamifySpacing.xxxl)
        }
        .background(Brand.surface.ignoresSafeArea())
        .safeAreaInset(edge: .top) {
            topBar(name: name)
                .padding(.horizontal, NamifySpacing.md)
                .padding(.top, 10)
                .padding(.bottom, NamifySpacing.sm)
                .background(.ultraThinMaterial)
        }
    }

    private func topBar(name: NameComponents) -> some View {
        HStack {
            Spacer()
            Text(name.first)
                .font(NamifyTypography.subtitle())
                .foregroundStyle(Brand.textPrimary)
                .lineLimit(1)
            Spacer()
        }
    }

    private func heroSection(name: NameComponents, summary: NameRunSummary) -> some View {
        VStack(alignment: .center, spacing: NamifySpacing.sm) {
            Text(name.displayName)
                .font(NamifyTypography.hero())
                .foregroundStyle(Brand.textPrimary)
                .multilineTextAlignment(.center)

            Text(String(localized: "results.label.testedToday"))
                .font(NamifyTypography.bodySmall())
                .foregroundStyle(Brand.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Brand.cardAlt, in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, NamifySpacing.lg)
    }

    private func cardsSection(name: NameComponents, results: [TestResult]) -> some View {
        VStack(spacing: NamifySpacing.md) {
            ForEach(results) { result in
                NamifyCard(
                    testType: result.testType,
                    summary: result.summaryLine,
                    verdict: result.verdict,
                    isExpanded: Binding(
                        get: { expandedCards.contains(result.id) },
                        set: { expanded in
                            if expanded {
                                expandedCards.insert(result.id)
                            } else {
                                expandedCards.remove(result.id)
                            }
                        }
                    )
                ) {
                    TestDetailView(result: result, name: name)
                }
            }
        }
    }

    private func verdictSection(summary: NameRunSummary) -> some View {
        VStack(spacing: NamifySpacing.md) {
            Rectangle()
                .fill(Brand.accent.opacity(0.6))
                .frame(width: 220, height: 1)
                .frame(maxWidth: .infinity)
                .padding(.top, NamifySpacing.lg)

            Image(systemName: "shield.checkered")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(summary.overallVerdict == .survived ? Brand.pass : (summary.overallVerdict == .mixed ? Brand.warn : Brand.fail))

            Text(String(localized: String.LocalizationValue(summary.overallVerdict.headlineKey)))
                .font(NamifyTypography.subtitle())
                .foregroundStyle(summary.overallVerdict == .survived ? Brand.pass : (summary.overallVerdict == .mixed ? Brand.warn : Brand.fail))
                .multilineTextAlignment(.center)

            Text(String(format: String(localized: "results.score"), summary.passCount, summary.results.count))
                .font(NamifyTypography.bodyMedium())
                .foregroundStyle(Brand.textSecondary)
        }
        .padding(.top, NamifySpacing.lg)
    }

    private var completionCTA: some View {
        VStack(spacing: NamifySpacing.md) {
            Text("onboarding.complete.message")
                .font(NamifyTypography.bodyMedium())
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, NamifySpacing.lg)

            NamifyButton(title: String(localized: "onboarding.complete.cta")) {
                Haptics.notification(.success)
                onComplete()
            }

            NamifyButton(title: String(localized: "onboarding.complete.secondary"), style: .text) {
                if let summary = viewModel.demoSummary,
                   let name = viewModel.demoName,
                   let image = ShareCardRenderer.renderReport(name: name, summary: summary, colorScheme: colorScheme) {
                    share(items: [image])
                }
            }
        }
    }

    private func share(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        rootVC.present(activityVC, animated: true)
    }
}

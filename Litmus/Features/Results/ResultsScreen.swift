import SwiftUI
import SwiftData
import UIKit

enum ResultsSource {
    case live(NameComponents)
    case saved(NameReport)
}

@MainActor
final class ResultsViewModel: ObservableObject {
    @Published var name: NameComponents
    @Published var results: [TestResult] = []
    @Published var summary: NameRunSummary?
    @Published var currentIndex = 0
    @Published var totalCount = 7
    @Published var currentTestType: TestType?
    @Published var isRunning = false

    private let source: ResultsSource
    private let engine = NameTestEngine()
    private var hasStarted = false

    init(source: ResultsSource) {
        self.source = source
        switch source {
        case .live(let name):
            self.name = name
        case .saved(let report):
            self.name = report.nameComponents
        }
    }

    func startIfNeeded(context: ModelContext, session: AppSession) {
        guard hasStarted == false else { return }
        hasStarted = true

        switch source {
        case .saved(let report):
            let loadedResults = report.testResults
            results = loadedResults
            summary = NameRunSummary(results: loadedResults, strictMode: session.preferences.strictMode)
            currentIndex = loadedResults.count
            totalCount = loadedResults.count
            isRunning = false
        case .live(let liveName):
            isRunning = true
            Task {
                do {
                    for try await event in engine.run(name: liveName, preferences: session.preferences) {
                        switch event {
                        case .started(let total):
                            totalCount = total
                        case .progress(let index, let total, let testType):
                            currentIndex = index
                            totalCount = total
                            currentTestType = testType
                        case .result(_, _, let result):
                            results.append(result)
                            if result.verdict == .pass {
                                Haptics.impact(.light)
                            } else if result.verdict == .warn {
                                Haptics.notification(.warning)
                            } else {
                                Haptics.notification(.error)
                            }
                        case .completed(let summary):
                            self.summary = summary
                            isRunning = false
                            do {
                                _ = try PersistenceService.shared.saveReport(name: liveName, summary: summary, context: context)
                                session.refreshHistoryCount(context: context)
                            } catch {
                                session.toast = ToastState(title: "Could not save. Results remain visible.", actionTitle: nil, action: nil)
                            }

                            switch summary.overallVerdict {
                            case .survived: Haptics.notification(.success)
                            case .mixed: Haptics.notification(.warning)
                            case .failed: Haptics.notification(.error)
                            }
                        }
                    }
                } catch {
                    session.toast = ToastState(title: "The test run was interrupted.", actionTitle: nil, action: nil)
                    isRunning = false
                }
            }
        }
    }

    var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(results.count) / Double(totalCount)
    }

    var progressLabel: String {
        guard let currentTestType else { return "" }
        return String(format: String(localized: "results.testing"), currentIndex, totalCount, String(localized: String.LocalizationValue(currentTestType.localizedNameKey)))
    }
}

struct ResultsScreen: View {
    let source: ResultsSource

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel: ResultsViewModel
    @State private var expandedCards: Set<UUID> = []
    @State private var shareItems: [Any] = []
    @State private var individualShareItem: Any?

    init(source: ResultsSource) {
        self.source = source
        _viewModel = StateObject(wrappedValue: ResultsViewModel(source: source))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LitmusSpacing.lg) {
                heroSection
                if viewModel.isRunning {
                    progressSection
                }
                cardsSection
                if let summary = viewModel.summary {
                    verdictSection(summary: summary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, LitmusSpacing.xxxl)
        }
        .background(Brand.surface.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            topBar
                .padding(.horizontal, LitmusSpacing.md)
                .padding(.top, 10)
                .padding(.bottom, LitmusSpacing.sm)
                .background(.ultraThinMaterial)
        }
        .sheet(isPresented: Binding(
            get: { shareItems.isEmpty == false },
            set: { if !$0 { shareItems = [] } }
        )) {
            ShareSheet(items: shareItems)
        }
        .task {
            viewModel.startIfNeeded(context: modelContext, session: session)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                coordinator.pop()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(LitmusTypography.bodyMedium())
                .foregroundStyle(Brand.accent)
            }
            .buttonStyle(.plain)
            Spacer()
            Text(viewModel.name.first)
                .font(LitmusTypography.subtitle())
                .foregroundStyle(Brand.textPrimary)
                .lineLimit(1)
            Spacer()
            Button {
                shareFullReport()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Brand.accent)
            }
            .buttonStyle(.plain)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .center, spacing: LitmusSpacing.sm) {
            Text(viewModel.name.displayName)
                .font(LitmusTypography.hero())
                .foregroundStyle(Brand.textPrimary)
                .multilineTextAlignment(.center)
                .onTapGesture {
                    UIPasteboard.general.string = viewModel.name.fullName
                    session.toast = ToastState(title: "Full name copied", actionTitle: nil, action: nil)
                }

            Text(sourceDateLabel)
                .font(LitmusTypography.bodySmall())
                .foregroundStyle(Brand.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Brand.cardAlt, in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, LitmusSpacing.lg)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: LitmusSpacing.sm) {
            LitmusProgressBar(progress: viewModel.progressFraction)
                .frame(height: 6)
            Text(viewModel.progressLabel)
                .font(LitmusTypography.bodySmall())
                .foregroundStyle(Brand.textSecondary)
        }
    }

    private var cardsSection: some View {
        VStack(spacing: LitmusSpacing.md) {
            ForEach(viewModel.results) { result in
                LitmusCard(
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
                    TestDetailView(result: result, name: viewModel.name)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        shareSingle(result)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tint(Brand.accent)
                }
            }
        }
    }

    @ViewBuilder
    private func verdictSection(summary: NameRunSummary) -> some View {
        VStack(spacing: LitmusSpacing.md) {
            Rectangle()
                .fill(Brand.accent.opacity(0.6))
                .frame(width: 220, height: 1)
                .frame(maxWidth: .infinity)
                .padding(.top, LitmusSpacing.lg)

            Image(systemName: "shield.checkered")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(summary.overallVerdict == .survived ? Brand.pass : (summary.overallVerdict == .mixed ? Brand.warn : Brand.fail))

            Text(String(localized: String.LocalizationValue(summary.overallVerdict.headlineKey)))
                .font(LitmusTypography.subtitle())
                .foregroundStyle(summary.overallVerdict == .survived ? Brand.pass : (summary.overallVerdict == .mixed ? Brand.warn : Brand.fail))
                .multilineTextAlignment(.center)
                .onLongPressGesture {
                    UIPasteboard.general.string = String(localized: String.LocalizationValue(summary.overallVerdict.headlineKey))
                    Haptics.impact(.heavy)
                    session.toast = ToastState(title: "Verdict copied", actionTitle: nil, action: nil)
                }

            Text(String(format: String(localized: "results.score"), summary.passCount, summary.results.count))
                .font(LitmusTypography.bodyMedium())
                .foregroundStyle(Brand.textSecondary)

            LitmusButton(title: String(localized: "results.share.cta")) {
                shareFullReport()
            }

            LitmusButton(title: String(localized: "results.another.cta"), style: .text) {
                coordinator.popToRoot()
            }
        }
        .padding(.top, LitmusSpacing.lg)
    }

    private var sourceDateLabel: String {
        switch source {
        case .live:
            return "Tested today"
        case .saved(let report):
            return report.testDate.litmusRelativeLabel
        }
    }

    private func shareFullReport() {
        guard let summary = viewModel.summary,
              let image = ShareCardRenderer.renderReport(name: viewModel.name, summary: summary, colorScheme: colorScheme)
        else {
            shareItems = [String(localized: String.LocalizationValue(viewModel.summary?.overallVerdict.headlineKey ?? "results.verdict.mixed"))]
            return
        }
        Haptics.impact(.medium)
        shareItems = [image]
    }

    private func shareSingle(_ result: TestResult) {
        if let image = ShareCardRenderer.renderSingleTest(name: viewModel.name, result: result, colorScheme: colorScheme) {
            shareItems = [image]
        } else {
            shareItems = [result.summaryLine, result.detailText]
        }
    }
}

private struct TestDetailView: View {
    let result: TestResult
    let name: NameComponents

    var body: some View {
        VStack(alignment: .leading, spacing: LitmusSpacing.md) {
            Text(result.detailText)
                .font(LitmusTypography.bodyMedium())
                .foregroundStyle(Brand.textPrimary)

            switch result.detailData {
            case .rhyme(let detail):
                rhyme(detail)
            case .initials(let detail):
                initials(detail)
            case .pronunciation(let detail):
                pronunciation(detail)
            case .email(let detail):
                email(detail)
            case .nameTag(let detail):
                nameTag(detail)
            case .namesake(let detail):
                namesakes(detail)
            case .monogram(let detail):
                monogram(detail)
            case .generic(let message):
                Text(message)
                    .font(LitmusTypography.bodySmall())
                    .foregroundStyle(Brand.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func rhyme(_ detail: RhymeDetail) -> some View {
        if detail.findings.isEmpty {
            Label("No rhyming vulnerabilities detected", systemImage: "checkmark.circle.fill")
                .font(LitmusTypography.bodyMedium())
                .foregroundStyle(Brand.pass)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(detail.findings, id: \.self) { item in
                    HStack {
                        Text(item.source)
                            .font(LitmusTypography.mono())
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundStyle(Brand.textTertiary)
                        Text(item.rhyme)
                            .font(LitmusTypography.mono())
                            .foregroundStyle(item.negative ? Brand.fail : Brand.textSecondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func initials(_ detail: InitialsDetail) -> some View {
        VStack(alignment: .center, spacing: LitmusSpacing.sm) {
            Text(detail.initials)
                .font(LitmusTypography.subtitle())
                .foregroundStyle(detail.matches.isEmpty ? Brand.pass : Brand.fail)
                .frame(maxWidth: .infinity)
            Text(detail.initials.replacingOccurrences(of: ".", with: " "))
                .font(LitmusTypography.mono())
                .foregroundStyle(Brand.textSecondary)
            if let match = detail.matches.first {
                Text("\(match.initials) — \(match.note)")
                    .font(LitmusTypography.bodySmall())
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No matches found in the bundled flagged-initials database.")
                    .font(LitmusTypography.bodySmall())
                    .foregroundStyle(Brand.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func pronunciation(_ detail: PronunciationDetail) -> some View {
        VStack(alignment: .leading, spacing: LitmusSpacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(detail.phonetic)
                    .font(LitmusTypography.mono())
                    .foregroundStyle(Brand.textPrimary)
                Text("Likely roll call miss: \(detail.likelyMispronunciation)")
                    .font(LitmusTypography.bodySmall())
                    .foregroundStyle(Brand.textSecondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Brand.divider)
                    Capsule()
                        .fill(LinearGradient(colors: [Brand.pass, Brand.warn, Brand.fail], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * CGFloat(detail.difficultyScore) / 10)
                    Circle()
                        .fill(Brand.card)
                        .overlay(Circle().stroke(Brand.accent, lineWidth: 2))
                        .frame(width: 18, height: 18)
                        .offset(x: max(0, proxy.size.width * CGFloat(detail.difficultyScore) / 10 - 9))
                }
            }
            .frame(height: 14)

            Text("Difficulty score: \(detail.difficultyScore)/10")
                .font(LitmusTypography.bodySmall())
                .foregroundStyle(Brand.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(detail.factors, id: \.self) { factor in
                    LitmusChip(title: factor.label, tint: Brand.color(for: factor.verdict).opacity(0.12), foreground: Brand.color(for: factor.verdict))
                    Text(factor.explanation)
                        .font(LitmusTypography.bodySmall())
                        .foregroundStyle(Brand.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func email(_ detail: EmailDetail) -> some View {
        VStack(alignment: .leading, spacing: LitmusSpacing.md) {
            VStack(spacing: 0) {
                ForEach(detail.variants, id: \.self) { variant in
                    HStack {
                        Text("\(variant.value)@\(variant.domain)")
                            .font(LitmusTypography.mono())
                            .foregroundStyle(Brand.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Circle()
                            .fill(statusColor(variant.status))
                            .frame(width: 8, height: 8)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, LitmusSpacing.md)
                    if variant != detail.variants.last {
                        LitmusDivider()
                    }
                }
            }
            .background(Brand.cardAlt, in: RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous))

            HStack {
                Text("Readability")
                    .font(LitmusTypography.bodySmall())
                    .foregroundStyle(Brand.textSecondary)
                Spacer()
                Text(detail.readability)
                    .font(LitmusTypography.badge())
                    .foregroundStyle(Brand.textPrimary)
            }
        }
    }

    @ViewBuilder
    private func nameTag(_ detail: NameTagDetail) -> some View {
        VStack(alignment: .center, spacing: LitmusSpacing.md) {
            RoundedRectangle(cornerRadius: LitmusRadius.medium, style: .continuous)
                .fill(.white)
                .frame(height: 110)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Brand.accent)
                        .frame(height: 8)
                }
                .overlay {
                    VStack(spacing: 8) {
                        Text("HELLO MY NAME IS")
                            .font(LitmusTypography.badge())
                            .foregroundStyle(Brand.textTertiary)
                            .kerning(1.4)
                        Text(detail.displayName)
                            .font(LitmusTypography.subtitle())
                            .foregroundStyle(Color.black.opacity(0.84))
                            .minimumScaleFactor(0.7)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 12)
                }
                .rotationEffect(.degrees(2))
                .shadow(color: Color.black.opacity(0.12), radius: 18, y: 6)

            Text(detail.fitsScore)
                .font(LitmusTypography.bodySmall())
                .foregroundStyle(Brand.textSecondary)
        }
    }

    @ViewBuilder
    private func namesakes(_ detail: NamesakeDetail) -> some View {
        if detail.entries.isEmpty {
            Text("No widely known historical figures share this name — a blank slate.")
                .font(LitmusTypography.bodyMedium())
                .foregroundStyle(Brand.textSecondary)
        } else {
            VStack(alignment: .leading, spacing: LitmusSpacing.md) {
                ForEach(detail.entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.fullName)
                            .font(LitmusTypography.bodyLarge())
                            .foregroundStyle(Brand.textPrimary)
                        Text(entry.shortBio)
                            .font(LitmusTypography.bodySmall())
                            .foregroundStyle(Brand.textSecondary)
                        LitmusChip(title: entry.sentiment.capitalized, tint: sentimentTint(entry.sentiment), foreground: sentimentForeground(entry.sentiment))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func monogram(_ detail: MonogramDetail) -> some View {
        VStack(alignment: .leading, spacing: LitmusSpacing.md) {
            HStack(spacing: LitmusSpacing.md) {
                ForEach(detail.previews, id: \.title) { preview in
                    MonogramPreviewCard(style: preview.title, initials: preview.initials)
                }
            }
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index < detail.score ? Brand.accent : Brand.divider)
                        .frame(width: 10, height: 10)
                }
            }
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "Likely Available": Brand.pass
        case "Likely Taken": Brand.fail
        default: Brand.warn
        }
    }

    private func sentimentTint(_ sentiment: String) -> Color {
        switch sentiment {
        case "positive": Brand.pass.opacity(0.12)
        case "negative": Brand.fail.opacity(0.12)
        case "mixed": Brand.warn.opacity(0.12)
        default: Brand.cardAlt
        }
    }

    private func sentimentForeground(_ sentiment: String) -> Color {
        switch sentiment {
        case "positive": Brand.pass
        case "negative": Brand.fail
        case "mixed": Brand.warn
        default: Brand.textSecondary
        }
    }
}

private struct MonogramPreviewCard: View {
    let style: String
    let initials: [String]

    var body: some View {
        VStack(spacing: LitmusSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Brand.cardAlt)
                Group {
                    switch style {
                    case "Classic":
                        HStack(alignment: .bottom, spacing: 4) {
                            Text(initials[0]).font(LitmusTypography.subtitle())
                            Text(initials[2]).font(LitmusTypography.hero())
                            Text(initials[1]).font(LitmusTypography.subtitle())
                        }
                    case "Stacked":
                        VStack(spacing: -4) {
                            HStack(spacing: 8) {
                                Text(initials[0])
                                Text(initials[1])
                            }
                            .font(LitmusTypography.subtitle())
                            Text(initials[2]).font(LitmusTypography.hero())
                        }
                    default:
                        ZStack {
                            Text(initials[0]).font(LitmusTypography.hero())
                            Text(initials[1]).font(LitmusTypography.hero()).opacity(0.6).offset(x: 6)
                            Text(initials[2]).font(LitmusTypography.hero()).opacity(0.4).offset(x: 12, y: 4)
                        }
                    }
                }
                .foregroundStyle(Brand.primary)
            }
            .frame(width: 100, height: 100)

            Text(style)
                .font(LitmusTypography.bodySmall())
                .foregroundStyle(Brand.textSecondary)
        }
    }
}

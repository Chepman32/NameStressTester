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
    @Published var totalCount = TestType.defaultOrder.count
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
                            guard result.testType.isAvailableInApp else { continue }
                            results.append(result)
                            if result.verdict == .pass {
                                Haptics.impact(.light)
                            } else if result.verdict == .warn {
                                Haptics.notification(.warning)
                            } else {
                                Haptics.notification(.error)
                            }
                        case .completed:
                            let visibleSummary = NameRunSummary(results: results, strictMode: session.preferences.strictMode)
                            self.summary = visibleSummary
                            isRunning = false
                            do {
                                _ = try PersistenceService.shared.saveReport(name: liveName, summary: visibleSummary, context: context)
                                session.refreshHistoryCount(context: context)
                            } catch {
                                session.toast = ToastState(title: String(localized: "results.toast.saveFailed"), actionTitle: nil, action: nil)
                            }

                            switch visibleSummary.overallVerdict {
                            case .survived: Haptics.notification(.success)
                            case .mixed: Haptics.notification(.warning)
                            case .failed: Haptics.notification(.error)
                            }
                        }
                    }
                } catch {
                    session.toast = ToastState(title: String(localized: "results.toast.interrupted"), actionTitle: nil, action: nil)
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
            VStack(alignment: .leading, spacing: NamifySpacing.lg) {
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
            .padding(.bottom, NamifySpacing.xxxl)
        }
        .background(Brand.surface.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            topBar
                .padding(.horizontal, NamifySpacing.md)
                .padding(.top, 10)
                .padding(.bottom, NamifySpacing.sm)
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
                    Text(String(localized: "results.button.back"))
                }
                .font(NamifyTypography.bodyMedium())
                .foregroundStyle(Brand.accent)
            }
            .buttonStyle(.plain)
            Spacer()
            Text(viewModel.name.first)
                .font(NamifyTypography.subtitle())
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
        VStack(alignment: .center, spacing: NamifySpacing.sm) {
            Text(viewModel.name.displayName)
                .font(NamifyTypography.hero())
                .foregroundStyle(Brand.textPrimary)
                .multilineTextAlignment(.center)
                .onTapGesture {
                    UIPasteboard.general.string = viewModel.name.fullName
                    session.toast = ToastState(title: String(localized: "results.toast.nameCopied"), actionTitle: nil, action: nil)
                }

            Text(sourceDateLabel)
                .font(NamifyTypography.bodySmall())
                .foregroundStyle(Brand.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Brand.cardAlt, in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, NamifySpacing.lg)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: NamifySpacing.sm) {
            NamifyProgressBar(progress: viewModel.progressFraction)
                .frame(height: 6)
            Text(viewModel.progressLabel)
                .font(NamifyTypography.bodySmall())
                .foregroundStyle(Brand.textSecondary)
        }
    }

    private var cardsSection: some View {
        VStack(spacing: NamifySpacing.md) {
            ForEach(viewModel.results) { result in
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
                    TestDetailView(result: result, name: viewModel.name)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        shareSingle(result)
                    } label: {
                        Label(String(localized: "results.swipe.share"), systemImage: "square.and.arrow.up")
                    }
                    .tint(Brand.accent)
                }
            }
        }
    }

    @ViewBuilder
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
                .onLongPressGesture {
                    UIPasteboard.general.string = String(localized: String.LocalizationValue(summary.overallVerdict.headlineKey))
                    Haptics.impact(.heavy)
                    session.toast = ToastState(title: String(localized: "results.toast.verdictCopied"), actionTitle: nil, action: nil)
                }

            Text(String(format: String(localized: "results.score"), summary.passCount, summary.results.count))
                .font(NamifyTypography.bodyMedium())
                .foregroundStyle(Brand.textSecondary)

            NamifyButton(title: String(localized: "results.share.cta")) {
                shareFullReport()
            }

            NamifyButton(title: String(localized: "results.another.cta"), style: .text) {
                coordinator.popToRoot()
            }
        }
        .padding(.top, NamifySpacing.lg)
    }

    private var sourceDateLabel: String {
        switch source {
        case .live:
            return String(localized: "results.label.testedToday")
        case .saved(let report):
            return report.testDate.namifyRelativeLabel
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

struct TestDetailView: View {
    let result: TestResult
    let name: NameComponents

    var body: some View {
        VStack(alignment: .leading, spacing: NamifySpacing.md) {
            Text(result.detailText)
                .font(NamifyTypography.bodyMedium())
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
                    .font(NamifyTypography.bodySmall())
                    .foregroundStyle(Brand.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func rhyme(_ detail: RhymeDetail) -> some View {
        if detail.findings.isEmpty {
            Label(String(localized: "results.detail.noRhymes"), systemImage: "checkmark.circle.fill")
                .font(NamifyTypography.bodyMedium())
                .foregroundStyle(Brand.pass)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(detail.findings, id: \.self) { item in
                    HStack {
                        Text(item.source)
                            .font(NamifyTypography.mono())
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundStyle(Brand.textTertiary)
                        Text(item.rhyme)
                            .font(NamifyTypography.mono())
                            .foregroundStyle(item.negative ? Brand.fail : Brand.textSecondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func initials(_ detail: InitialsDetail) -> some View {
        VStack(alignment: .center, spacing: NamifySpacing.sm) {
            Text(detail.initials)
                .font(NamifyTypography.subtitle())
                .foregroundStyle(detail.matches.isEmpty ? Brand.pass : Brand.fail)
                .frame(maxWidth: .infinity)
            Text(detail.initials.replacingOccurrences(of: ".", with: " "))
                .font(NamifyTypography.mono())
                .foregroundStyle(Brand.textSecondary)
            if let match = detail.matches.first {
                Text("\(match.initials) — \(localizedInitialsNote(match.note))")
                    .font(NamifyTypography.bodySmall())
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text(String(localized: "results.detail.noMatches"))
                    .font(NamifyTypography.bodySmall())
                    .foregroundStyle(Brand.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func pronunciation(_ detail: PronunciationDetail) -> some View {
        VStack(alignment: .leading, spacing: NamifySpacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(detail.phonetic)
                    .font(NamifyTypography.mono())
                    .foregroundStyle(Brand.textPrimary)
                Text(String(format: String(localized: "results.detail.rollCallMiss"), detail.likelyMispronunciation))
                    .font(NamifyTypography.bodySmall())
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

            Text(String(format: String(localized: "results.detail.difficultyScore"), detail.difficultyScore))
                .font(NamifyTypography.bodySmall())
                .foregroundStyle(Brand.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(detail.factors, id: \.self) { factor in
                    NamifyChip(title: factor.label, tint: Brand.color(for: factor.verdict).opacity(0.12), foreground: Brand.color(for: factor.verdict))
                    Text(factor.explanation)
                        .font(NamifyTypography.bodySmall())
                        .foregroundStyle(Brand.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func email(_ detail: EmailDetail) -> some View {
        VStack(alignment: .leading, spacing: NamifySpacing.md) {
            VStack(spacing: 0) {
                ForEach(detail.variants, id: \.self) { variant in
                    HStack {
                        Text("\(variant.value)@\(variant.domain)")
                            .font(NamifyTypography.mono())
                            .foregroundStyle(Brand.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Circle()
                            .fill(statusColor(variant.status))
                            .frame(width: 8, height: 8)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, NamifySpacing.md)
                    if variant != detail.variants.last {
                        NamifyDivider()
                    }
                }
            }
            .background(Brand.cardAlt, in: RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous))

            HStack {
                Text(String(localized: "results.detail.readability"))
                    .font(NamifyTypography.bodySmall())
                    .foregroundStyle(Brand.textSecondary)
                Spacer()
                Text(localizedReadability(detail.readability))
                    .font(NamifyTypography.badge())
                    .foregroundStyle(Brand.textPrimary)
            }
        }
    }

    @ViewBuilder
    private func nameTag(_ detail: NameTagDetail) -> some View {
        VStack(alignment: .center, spacing: NamifySpacing.md) {
            RoundedRectangle(cornerRadius: NamifyRadius.medium, style: .continuous)
                .fill(.white)
                .frame(height: 110)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Brand.accent)
                        .frame(height: 8)
                }
                .overlay {
                    VStack(spacing: 8) {
                        Text(String(localized: "results.detail.helloMyNameIs"))
                            .font(NamifyTypography.badge())
                            .foregroundStyle(Brand.textTertiary)
                            .kerning(1.4)
                        Text(detail.displayName)
                            .font(NamifyTypography.subtitle())
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
                .font(NamifyTypography.bodySmall())
                .foregroundStyle(Brand.textSecondary)
        }
    }

    @ViewBuilder
    private func namesakes(_ detail: NamesakeDetail) -> some View {
        if detail.entries.isEmpty {
            Text(String(localized: "results.detail.blankSlate"))
                .font(NamifyTypography.bodyMedium())
                .foregroundStyle(Brand.textSecondary)
        } else {
            VStack(alignment: .leading, spacing: NamifySpacing.md) {
                ForEach(detail.entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.fullName)
                            .font(NamifyTypography.bodyLarge())
                            .foregroundStyle(Brand.textPrimary)
                        Text(localizedNamesakeBio(entry))
                            .font(NamifyTypography.bodySmall())
                            .foregroundStyle(Brand.textSecondary)
                        NamifyChip(title: localizedSentiment(entry.sentiment), tint: sentimentTint(entry.sentiment), foreground: sentimentForeground(entry.sentiment))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func monogram(_ detail: MonogramDetail) -> some View {
        VStack(alignment: .leading, spacing: NamifySpacing.md) {
            HStack(spacing: NamifySpacing.md) {
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

    private func localizedSentiment(_ sentiment: String) -> String {
        switch sentiment {
        case "positive": return String(localized: "results.sentiment.positive")
        case "negative": return String(localized: "results.sentiment.negative")
        case "mixed": return String(localized: "results.sentiment.mixed")
        default: return sentiment.capitalized
        }
    }

    private func localizedReadability(_ readability: String) -> String {
        switch readability {
        case "EASY": return String(localized: "email.readability.easy")
        case "MODERATE": return String(localized: "email.readability.moderate")
        case "DIFFICULT": return String(localized: "email.readability.difficult")
        default: return readability
        }
    }

    private func localizedInitialsNote(_ note: String) -> String {
        switch note {
        case "Common profanity": return String(localized: "initials.note.profanity")
        case "Medical acronym with social baggage": return String(localized: "initials.note.medical")
        case "Suggestive abbreviation": return String(localized: "initials.note.suggestive")
        case "Hate-group reference": return String(localized: "initials.note.hate")
        case "Negative plain-English word": return String(localized: "initials.note.negative")
        case "Common teasing target": return String(localized: "initials.note.teasing")
        case "Profane slang acronym": return String(localized: "initials.note.slang")
        default: return note
        }
    }

    private func localizedNamesakeBio(_ entry: NamesakeEntry) -> String {
        switch entry.fullName {
        case "Ada Lovelace": return String(localized: "namesake.ada.bio")
        case "Attila the Hun": return String(localized: "namesake.attila.bio")
        case "Cleopatra": return String(localized: "namesake.cleo.bio")
        case "James Baldwin": return String(localized: "namesake.james.baldwin.bio")
        case "James Dean": return String(localized: "namesake.james.dean.bio")
        case "John Wayne Gacy": return String(localized: "namesake.john.gacy.bio")
        case "John Lennon": return String(localized: "namesake.john.lennon.bio")
        case "Mary Shelley": return String(localized: "namesake.mary.shelley.bio")
        case "Bloody Mary": return String(localized: "namesake.mary.bloody.bio")
        case "Adolf Hitler": return String(localized: "namesake.adolf.bio")
        case "Ulysses S. Grant": return String(localized: "namesake.ulysses.bio")
        case "Wolf Blitzer": return String(localized: "namesake.wolf.bio")
        case "Zelda Fitzgerald": return String(localized: "namesake.zelda.bio")
        default: return entry.shortBio
        }
    }
}

private struct MonogramPreviewCard: View {
    let style: String
    let initials: [String]

    private var localizedStyle: String {
        switch style {
        case "Classic": return String(localized: "monogram.style.classic")
        case "Stacked": return String(localized: "monogram.style.stacked")
        default: return String(localized: "monogram.style.interleaved")
        }
    }

    var body: some View {
        VStack(spacing: NamifySpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Brand.cardAlt)
                Group {
                    switch style {
                    case "Classic":
                        HStack(alignment: .bottom, spacing: 4) {
                            Text(initials[0]).font(NamifyTypography.subtitle())
                            Text(initials[2]).font(NamifyTypography.hero())
                            Text(initials[1]).font(NamifyTypography.subtitle())
                        }
                    case "Stacked":
                        VStack(spacing: -4) {
                            HStack(spacing: 8) {
                                Text(initials[0])
                                Text(initials[1])
                            }
                            .font(NamifyTypography.subtitle())
                            Text(initials[2]).font(NamifyTypography.hero())
                        }
                    default:
                        ZStack {
                            Text(initials[0]).font(NamifyTypography.hero())
                            Text(initials[1]).font(NamifyTypography.hero()).opacity(0.6).offset(x: 6)
                            Text(initials[2]).font(NamifyTypography.hero()).opacity(0.4).offset(x: 12, y: 4)
                        }
                    }
                }
                .foregroundStyle(Brand.primary)
            }
            .frame(width: 100, height: 100)

            Text(localizedStyle)
                .font(NamifyTypography.bodySmall())
                .foregroundStyle(Brand.textSecondary)
        }
    }
}

import SwiftUI
import SwiftData

private struct DeletedReportSnapshot {
    let id: UUID
    let name: NameComponents
    let testDate: Date
    let overallVerdict: OverallVerdict
    let passCount: Int
    let warnCount: Int
    let failCount: Int
    let results: [TestResult]
    let isFavorited: Bool

    init(report: NameReport) {
        id = report.id
        name = report.nameComponents
        testDate = report.testDate
        overallVerdict = report.overallVerdict
        passCount = report.passCount
        warnCount = report.warnCount
        failCount = report.failCount
        results = report.testResults
        isFavorited = report.isFavorited
    }

    func restore(into context: ModelContext) throws {
        let report = NameReport(
            id: id,
            name: name,
            testDate: testDate,
            overallVerdict: overallVerdict,
            passCount: passCount,
            warnCount: warnCount,
            failCount: failCount,
            testResults: results,
            isFavorited: isFavorited
        )
        context.insert(report)
        try context.save()
    }
}

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var query = ""
    @Published var sortOrder: HistorySortOrder = .mostRecent
    @Published var reports: [NameReport] = []

    func reload(context: ModelContext) {
        reports = (try? PersistenceService.shared.fetchHistory(query: query, sortOrder: sortOrder, context: context)) ?? []
    }

    func cycleSort(context: ModelContext) {
        let all = HistorySortOrder.allCases
        guard let index = all.firstIndex(of: sortOrder) else { return }
        sortOrder = all[(index + 1) % all.count]
        reload(context: context)
    }
}

struct HistoryScreen: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel = HistoryViewModel()
    @State private var deletedSnapshot: DeletedReportSnapshot?

    var body: some View {
        Group {
            if viewModel.reports.isEmpty && viewModel.query.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background(Brand.surface.ignoresSafeArea())
        .safeAreaInset(edge: .top) {
            topBar
                .padding(.horizontal, LitmusSpacing.md)
                .padding(.top, 10)
                .padding(.bottom, LitmusSpacing.sm)
                .background(.ultraThinMaterial)
        }
        .searchable(text: $viewModel.query, placement: .automatic, prompt: String(localized: "history.search.placeholder"))
        .onChange(of: viewModel.query) { _, _ in viewModel.reload(context: modelContext) }
        .task {
            viewModel.reload(context: modelContext)
            session.refreshHistoryCount(context: modelContext)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                coordinator.pop()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Input")
                }
                .font(LitmusTypography.bodyMedium())
                .foregroundStyle(Brand.accent)
            }
            .buttonStyle(.plain)

            Spacer()
            Text(String(localized: "history.title"))
                .font(LitmusTypography.subtitle())
                .foregroundStyle(Brand.textPrimary)
            Spacer()
            Button {
                viewModel.cycleSort(context: modelContext)
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 18, weight: .medium))
                    Text(viewModel.sortOrder.label)
                        .font(LitmusTypography.bodySmall())
                }
                .foregroundStyle(Brand.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(spacing: LitmusSpacing.lg) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundStyle(Brand.textTertiary)
            Text(String(localized: "history.empty.title"))
                .font(LitmusTypography.subtitle())
                .foregroundStyle(Brand.textTertiary)
            Text(String(localized: "history.empty.subtitle"))
                .font(LitmusTypography.bodyMedium())
                .foregroundStyle(Brand.textSecondary)
            LitmusButton(title: String(localized: "history.empty.cta"), style: .secondary) {
                coordinator.pop()
            }
            .frame(maxWidth: 240)
            Spacer()
        }
        .padding(.horizontal, LitmusSpacing.xl)
    }

    private var content: some View {
        List {
            ForEach(viewModel.reports, id: \.id) { report in
                Button {
                    coordinator.push(.savedReport(report.id))
                } label: {
                    HStack(spacing: LitmusSpacing.md) {
                        LitmusScoreRing(value: report.displayPassCount, total: max(report.displayTotalCount, 1))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(report.fullName)
                                .font(LitmusTypography.bodyLarge())
                                .foregroundStyle(Brand.textPrimary)
                            HStack(spacing: 6) {
                                Text(report.testDate.litmusRelativeLabel)
                                if report.isFavorited {
                                    Image(systemName: "heart.fill")
                                        .foregroundStyle(Brand.accent)
                                }
                            }
                            .font(LitmusTypography.bodySmall())
                            .foregroundStyle(Brand.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Brand.textTertiary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .listRowBackground(Brand.surface)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        try? PersistenceService.shared.toggleFavorite(report, context: modelContext)
                        viewModel.reload(context: modelContext)
                    } label: {
                        Label("Favorite", systemImage: "heart.fill")
                    }
                    .tint(Brand.warn)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deletedSnapshot = DeletedReportSnapshot(report: report)
                        try? PersistenceService.shared.deleteReport(report, context: modelContext)
                        viewModel.reload(context: modelContext)
                        session.refreshHistoryCount(context: modelContext)
                        session.toast = ToastState(
                            title: String(localized: "history.delete.undo"),
                            actionTitle: String(localized: "history.delete.undo.button"),
                            action: {
                                guard let deletedSnapshot else { return }
                                try? deletedSnapshot.restore(into: modelContext)
                                viewModel.reload(context: modelContext)
                                session.refreshHistoryCount(context: modelContext)
                                self.deletedSnapshot = nil
                            }
                        )
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Brand.surface)
    }
}

import SwiftUI
import SwiftData

@main
struct LitmusApp: App {
    private let container: ModelContainer = {
        let schema = Schema([NameReport.self, UserPreferences.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .environmentObject(coordinator)
                .environmentObject(session)
                .preferredColorScheme(session.preferredColorScheme)
        }
        .modelContainer(container)
    }
}

private struct RootContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var session: AppSession

    var body: some View {
        ZStack(alignment: .bottom) {
            if session.splashFinished {
                NavigationStack(path: $coordinator.path) {
                    InputScreen()
                        .navigationDestination(for: AppRoute.self, destination: destination(for:))
                }
                .sheet(item: $coordinator.sheet) { sheet in
                    switch sheet {
                    case .settings:
                        NavigationStack {
                            SettingsScreen()
                        }
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                    }
                }
            } else {
                SplashScreen {
                    withAnimation(LitmusMotion.gentle) {
                        session.splashFinished = true
                    }
                }
            }

            if let toast = session.toast {
                LitmusToast(title: toast.title, actionTitle: toast.actionTitle, action: toast.action)
                    .padding(.horizontal, LitmusSpacing.md)
                    .padding(.bottom, LitmusSpacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Brand.surface.ignoresSafeArea())
        .task {
            await session.bootstrap(context: modelContext)
        }
        .onChange(of: session.toast?.id) { _, _ in
            guard session.toast != nil else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                withAnimation {
                    session.toast = nil
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .history:
            HistoryScreen()
        case .results(let name):
            ResultsScreen(source: .live(name))
        case .savedReport(let reportID):
            SavedReportHost(reportID: reportID)
        }
    }
}

private struct SavedReportHost: View {
    let reportID: UUID
    @Environment(\.modelContext) private var modelContext
    @State private var report: NameReport?

    var body: some View {
        Group {
            if let report {
                ResultsScreen(source: .saved(report))
            } else {
                ProgressView()
                    .tint(Brand.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Brand.surface.ignoresSafeArea())
            }
        }
        .task {
            let descriptor = FetchDescriptor<NameReport>()
            report = try? modelContext.fetch(descriptor).first(where: { $0.id == reportID })
        }
    }
}

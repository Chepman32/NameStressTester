import Foundation

struct NameTestEngine {
    let store: OfflineDatasetStore

    init(store: OfflineDatasetStore = .shared) {
        self.store = store
    }

    func run(
        name: NameComponents,
        preferences: UserPreferencesSnapshot
    ) -> AsyncThrowingStream<NameTestEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let orderedTypes = TestType.sanitizedOrder(preferences.testOrder)
                continuation.yield(.started(total: orderedTypes.count))

                var results: [TestResult] = []

                for (index, type) in orderedTypes.enumerated() {
                    continuation.yield(.progress(index: index + 1, total: orderedTypes.count, testType: type))
                    try? await Task.sleep(for: .milliseconds(220))
                    let result = await execute(type: type, name: name, preferences: preferences)
                    results.append(result)
                    continuation.yield(.result(index: index + 1, total: orderedTypes.count, result: result))
                }

                let summary = NameRunSummary(results: results, strictMode: preferences.strictMode)
                continuation.yield(.completed(summary))
                continuation.finish()
            }
        }
    }

    private func execute(type: TestType, name: NameComponents, preferences: UserPreferencesSnapshot) async -> TestResult {
        switch type {
        case .rhyme:
            return await RhymeVulnerabilityAnalyzer(store: store).analyze(name: name)
        case .initials:
            return await InitialsDetector(store: store).analyze(name: name)
        case .pronunciation:
            return await PronunciationTester(store: store).analyze(name: name)
        case .email:
            return await EmailSimulator(store: store).analyze(name: name)
        case .nameTag:
            return await NameTagPreviewGenerator().analyze(name: name, includeMiddleName: preferences.includeMiddleName)
        case .namesake:
            return await HistoricalNamesakeEngine(store: store).analyze(name: name)
        case .monogram:
            return await MonogramAnalyzer().analyze(name: name)
        }
    }
}

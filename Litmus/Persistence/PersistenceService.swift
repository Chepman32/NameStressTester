import Foundation
import SwiftData

@MainActor
final class PersistenceService {
    static let shared = PersistenceService()

    private init() {}

    func bootstrapPreferences(context: ModelContext) throws -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>()
        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        let created = UserPreferences()
        context.insert(created)
        try context.save()
        return created
    }

    func loadPreferences(context: ModelContext) throws -> UserPreferencesSnapshot {
        try bootstrapPreferences(context: context).snapshot
    }

    func savePreferences(_ snapshot: UserPreferencesSnapshot, context: ModelContext) throws {
        let stored = try bootstrapPreferences(context: context)
        stored.apply(snapshot)
        try context.save()
    }

    @discardableResult
    func saveReport(
        name: NameComponents,
        summary: NameRunSummary,
        context: ModelContext
    ) throws -> NameReport {
        let report = NameReport(
            name: name,
            testDate: Date(),
            overallVerdict: summary.overallVerdict,
            passCount: summary.passCount,
            warnCount: summary.warnCount,
            failCount: summary.failCount,
            testResults: summary.results
        )
        context.insert(report)
        try context.save()
        return report
    }

    func fetchHistory(
        query: String,
        sortOrder: HistorySortOrder,
        context: ModelContext
    ) throws -> [NameReport] {
        let descriptor = FetchDescriptor<NameReport>()
        let reports = try context.fetch(descriptor)
        let filtered = reports.filter { report in
            guard query.isEmpty == false else { return true }
            return report.fullName.localizedStandardContains(query)
        }

        switch sortOrder {
        case .mostRecent:
            return filtered.sorted { $0.testDate > $1.testDate }
        case .alphabeticalAZ:
            return filtered.sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
        case .alphabeticalZA:
            return filtered.sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedDescending }
        case .bestScoreFirst:
            return filtered.sorted { ($0.displayPassCount, $0.testDate) > ($1.displayPassCount, $1.testDate) }
        case .worstScoreFirst:
            return filtered.sorted { ($0.displayPassCount, $0.testDate) < ($1.displayPassCount, $1.testDate) }
        }
    }

    func favoriteCount(context: ModelContext) throws -> Int {
        try context.fetch(FetchDescriptor<NameReport>()).count(where: \.isFavorited)
    }

    func historyCount(context: ModelContext) throws -> Int {
        try context.fetchCount(FetchDescriptor<NameReport>())
    }

    func deleteReport(_ report: NameReport, context: ModelContext) throws {
        context.delete(report)
        try context.save()
    }

    func clearAllHistory(context: ModelContext) throws {
        try context.fetch(FetchDescriptor<NameReport>()).forEach(context.delete(_:))
        try context.save()
    }

    func toggleFavorite(_ report: NameReport, context: ModelContext) throws {
        report.isFavorited.toggle()
        try context.save()
    }

    func exportHistoryJSON(context: ModelContext) throws -> Data {
        let reports = try context.fetch(FetchDescriptor<NameReport>())
        let export = reports.map { report in
            ExportReport(
                id: report.id,
                fullName: report.fullName,
                initials: report.initials,
                testDate: report.testDate,
                overallVerdict: report.overallVerdict.rawValue,
                passCount: report.displayPassCount,
                warnCount: report.displayWarnCount,
                failCount: report.displayFailCount,
                isFavorited: report.isFavorited,
                results: report.testResults
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(export)
    }
}

private struct ExportReport: Codable {
    let id: UUID
    let fullName: String
    let initials: String
    let testDate: Date
    let overallVerdict: String
    let passCount: Int
    let warnCount: Int
    let failCount: Int
    let isFavorited: Bool
    let results: [TestResult]
}

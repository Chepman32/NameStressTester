import Foundation
import SwiftData

@Model
final class NameReport {
    @Attribute(.unique) var id: UUID
    var firstName: String
    var middleName: String?
    var lastName: String
    var testDate: Date
    var overallVerdictRaw: String
    var passCount: Int
    var warnCount: Int
    var failCount: Int
    var testResultsJSON: String
    var isFavorited: Bool

    init(
        id: UUID = UUID(),
        name: NameComponents,
        testDate: Date,
        overallVerdict: OverallVerdict,
        passCount: Int,
        warnCount: Int,
        failCount: Int,
        testResults: [TestResult],
        isFavorited: Bool = false
    ) {
        self.id = id
        self.firstName = name.first
        self.middleName = name.middle
        self.lastName = name.last
        self.testDate = testDate
        self.overallVerdictRaw = overallVerdict.rawValue
        self.passCount = passCount
        self.warnCount = warnCount
        self.failCount = failCount
        self.testResultsJSON = NameReport.encoderString(from: testResults)
        self.isFavorited = isFavorited
    }

    var fullName: String {
        [firstName, middleName, lastName].compactMap { $0 }.joined(separator: " ")
    }

    var initials: String {
        NameComponents(first: firstName, middle: middleName, last: lastName).initials
    }

    var overallVerdict: OverallVerdict {
        get { OverallVerdict(rawValue: overallVerdictRaw) ?? .mixed }
        set { overallVerdictRaw = newValue.rawValue }
    }

    var nameComponents: NameComponents {
        NameComponents(first: firstName, middle: middleName, last: lastName)
    }

    var testResults: [TestResult] {
        get {
            guard let data = testResultsJSON.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([TestResult].self, from: data)) ?? []
        }
        set {
            testResultsJSON = NameReport.encoderString(from: newValue)
        }
    }

    private static func encoderString(from results: [TestResult]) -> String {
        guard
            let data = try? JSONEncoder().encode(results),
            let string = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return string
    }
}

@Model
final class UserPreferences {
    @Attribute(.unique) var id: UUID
    var appearanceModeRaw: String
    var includeMiddleName: Bool
    var strictMode: Bool
    var testOrderRaw: String
    var hasSeenOnboarding: Bool

    init(snapshot: UserPreferencesSnapshot = .default) {
        self.id = UUID()
        self.appearanceModeRaw = snapshot.appearanceMode.rawValue
        self.includeMiddleName = snapshot.includeMiddleName
        self.strictMode = snapshot.strictMode
        self.testOrderRaw = UserPreferences.encode(snapshot.testOrder)
        self.hasSeenOnboarding = snapshot.hasSeenOnboarding
    }

    var snapshot: UserPreferencesSnapshot {
        UserPreferencesSnapshot(
            appearanceMode: AppearanceMode(rawValue: appearanceModeRaw) ?? .system,
            includeMiddleName: includeMiddleName,
            strictMode: strictMode,
            testOrder: UserPreferences.decode(testOrderRaw),
            hasSeenOnboarding: hasSeenOnboarding
        )
    }

    func apply(_ snapshot: UserPreferencesSnapshot) {
        appearanceModeRaw = snapshot.appearanceMode.rawValue
        includeMiddleName = snapshot.includeMiddleName
        strictMode = snapshot.strictMode
        testOrderRaw = UserPreferences.encode(snapshot.testOrder)
        hasSeenOnboarding = snapshot.hasSeenOnboarding
    }

    private static func encode(_ order: [TestType]) -> String {
        guard
            let data = try? JSONEncoder().encode(order),
            let string = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return string
    }

    private static func decode(_ string: String) -> [TestType] {
        guard let data = string.data(using: .utf8),
              let order = try? JSONDecoder().decode([TestType].self, from: data)
        else {
            return TestType.defaultOrder
        }
        return order
    }
}

enum HistorySortOrder: String, CaseIterable, Identifiable {
    case mostRecent
    case alphabeticalAZ
    case alphabeticalZA
    case bestScoreFirst
    case worstScoreFirst

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mostRecent: "Recent"
        case .alphabeticalAZ: "A-Z"
        case .alphabeticalZA: "Z-A"
        case .bestScoreFirst: "Best"
        case .worstScoreFirst: "Worst"
        }
    }
}

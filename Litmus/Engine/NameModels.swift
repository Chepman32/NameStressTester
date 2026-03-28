import Foundation

enum TestVerdict: String, Codable, CaseIterable, Hashable {
    case pass
    case warn
    case fail

    var labelKey: String {
        switch self {
        case .pass: "badge.pass"
        case .warn: "badge.warn"
        case .fail: "badge.fail"
        }
    }
}

enum OverallVerdict: String, Codable, CaseIterable, Hashable {
    case survived
    case mixed
    case failed

    var headlineKey: String {
        switch self {
        case .survived: "results.verdict.survived"
        case .mixed: "results.verdict.mixed"
        case .failed: "results.verdict.failed"
        }
    }

    static func from(results: [TestResult], strictMode: Bool) -> OverallVerdict {
        let passCount = results.filter { $0.verdict == .pass }.count
        let warnCount = results.filter { $0.verdict == .warn }.count
        let failCount = results.filter { $0.verdict == .fail }.count

        let effectivePassCount = strictMode ? passCount : passCount + warnCount
        let _ = strictMode ? failCount + warnCount : failCount

        switch effectivePassCount {
        case 5...:
            return .survived
        case 3...4:
            return .mixed
        default:
            return .failed
        }
    }
}

enum TestType: String, Codable, CaseIterable, Hashable, Identifiable {
    case rhyme
    case initials
    case pronunciation
    case email
    case nameTag
    case namesake
    case monogram

    var id: String { rawValue }

    static let defaultOrder: [TestType] = [.rhyme, .initials, .pronunciation, .email, .nameTag, .namesake, .monogram]

    var localizedNameKey: String {
        switch self {
        case .rhyme: "test.rhyme.name"
        case .initials: "test.initials.name"
        case .pronunciation: "test.pronunciation.name"
        case .email: "test.email.name"
        case .nameTag: "test.nametag.name"
        case .namesake: "test.namesake.name"
        case .monogram: "test.monogram.name"
        }
    }

    var systemImage: String {
        switch self {
        case .rhyme: "music.note.list"
        case .initials: "textformat.abc"
        case .pronunciation: "waveform.and.person.filled"
        case .email: "envelope.badge.shield.half.filled"
        case .nameTag: "person.text.rectangle"
        case .namesake: "book.closed.fill"
        case .monogram: "seal.fill"
        }
    }
}

struct NameComponents: Codable, Hashable {
    let first: String
    let middle: String?
    let last: String

    init(first: String, middle: String?, last: String) {
        self.first = NameComponents.normalize(first)
        let trimmedMiddle = middle?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.middle = trimmedMiddle?.isEmpty == true ? nil : NameComponents.normalize(trimmedMiddle ?? "")
        self.last = NameComponents.normalize(last)
    }

    var initials: String {
        [first.first, middle?.first, last.first]
            .compactMap { $0.map { String($0).uppercased() } }
            .joined(separator: ".") + "."
    }

    var shortInitials: String {
        [first.first, last.first]
            .compactMap { $0.map { String($0).uppercased() } }
            .joined(separator: ".") + "."
    }

    var fullName: String {
        [first, middle, last]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    var displayName: String {
        middle.map { "\(first)\n\($0) \(last)" } ?? "\(first)\n\(last)"
    }

    var monogramLetters: [String] {
        let firstInitial = String(first.prefix(1)).uppercased()
        let middleInitial = middle.map { String($0.prefix(1)).uppercased() } ?? firstInitial
        let lastInitial = String(last.prefix(1)).uppercased()
        return [firstInitial, middleInitial, lastInitial]
    }

    var normalizedTokens: [String] {
        [first, middle, last]
            .compactMap { $0 }
            .map(\.litmusNormalized)
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .map { fragment in
                fragment
                    .prefix(1)
                    .uppercased() + fragment.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }
}

struct TestResult: Identifiable, Codable, Hashable {
    let id: UUID
    let testType: TestType
    let verdict: TestVerdict
    let summaryLine: String
    let detailText: String
    let detailData: TestDetailData

    init(
        id: UUID = UUID(),
        testType: TestType,
        verdict: TestVerdict,
        summaryLine: String,
        detailText: String,
        detailData: TestDetailData
    ) {
        self.id = id
        self.testType = testType
        self.verdict = verdict
        self.summaryLine = summaryLine
        self.detailText = detailText
        self.detailData = detailData
    }
}

struct NameRunSummary: Hashable {
    let results: [TestResult]
    let overallVerdict: OverallVerdict
    let passCount: Int
    let warnCount: Int
    let failCount: Int

    init(results: [TestResult], strictMode: Bool) {
        self.results = results
        self.passCount = results.filter { $0.verdict == .pass }.count
        self.warnCount = results.filter { $0.verdict == .warn }.count
        self.failCount = results.filter { $0.verdict == .fail }.count
        self.overallVerdict = OverallVerdict.from(results: results, strictMode: strictMode)
    }
}

enum NameTestEvent: Hashable {
    case started(total: Int)
    case progress(index: Int, total: Int, testType: TestType)
    case result(index: Int, total: Int, result: TestResult)
    case completed(NameRunSummary)
}

enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
}

struct UserPreferencesSnapshot: Codable, Hashable {
    var appearanceMode: AppearanceMode
    var includeMiddleName: Bool
    var strictMode: Bool
    var testOrder: [TestType]
    var hasSeenOnboarding: Bool

    static let `default` = UserPreferencesSnapshot(
        appearanceMode: .system,
        includeMiddleName: true,
        strictMode: false,
        testOrder: TestType.defaultOrder,
        hasSeenOnboarding: false
    )
}

struct HistoryItem: Identifiable, Hashable {
    let id: UUID
    let report: NameReport

    init(report: NameReport) {
        self.id = report.id
        self.report = report
    }
}

extension String {
    var litmusNormalized: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    var litmusLettersOnly: String {
        unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init)
            .joined()
            .lowercased()
    }
}

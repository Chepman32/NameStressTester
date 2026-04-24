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

    static let defaultOrder: [TestType] = [.rhyme, .initials, .pronunciation, .nameTag, .namesake, .monogram]

    var isAvailableInApp: Bool {
        self != .email
    }

    static func sanitizedOrder(_ order: [TestType]) -> [TestType] {
        var sanitized: [TestType] = []
        for type in order where type.isAvailableInApp && sanitized.contains(type) == false {
            sanitized.append(type)
        }
        return sanitized.isEmpty ? defaultOrder : sanitized
    }

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

extension Array where Element == TestResult {
    var visibleInApp: [TestResult] {
        filter { $0.testType.isAvailableInApp }
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
            .map(\.namifyNormalized)
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

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case system
    case english = "en"
    case arabic = "ar"
    case chineseSimplified = "zh-Hans"
    case czech = "cs"
    case danish = "da"
    case dutch = "nl"
    case finnish = "fi"
    case french = "fr"
    case german = "de"
    case greek = "el"
    case hebrew = "he"
    case hindi = "hi"
    case hungarian = "hu"
    case indonesian = "id"
    case italian = "it"
    case japanese = "ja"
    case korean = "ko"
    case malay = "ms"
    case norwegian = "no"
    case norwegianBokmal = "nb"
    case polish = "pl"
    case portugueseBrazil = "pt-BR"
    case romanian = "ro"
    case russian = "ru"
    case spanish = "es"
    case swedish = "sv"
    case thai = "th"
    case turkish = "tr"
    case ukrainian = "uk"
    case vietnamese = "vi"

    var id: String { rawValue }

    private static let availableCases: [AppLanguage] = [
        .english,
        .arabic,
        .chineseSimplified,
        .czech,
        .danish,
        .dutch,
        .finnish,
        .french,
        .german,
        .greek,
        .hebrew,
        .hindi,
        .indonesian,
        .italian,
        .japanese,
        .korean,
        .norwegian,
        .polish,
        .portugueseBrazil,
        .russian,
        .spanish,
        .swedish,
        .thai,
        .turkish,
        .ukrainian,
        .vietnamese
    ]

    static let supportedCases: [AppLanguage] = availableCases.sorted {
        $0.sortName.localizedStandardCompare($1.sortName) == .orderedAscending
    }

    static let selectableCases: [AppLanguage] = [.system] + supportedCases

    var supportedOrSystem: AppLanguage {
        Self.selectableCases.contains(self) ? self : .system
    }

    var displayName: String {
        let nativeLocale = Locale(identifier: rawValue)
        return nativeLocale.localizedString(forIdentifier: rawValue)
            ?? Locale.current.localizedString(forIdentifier: rawValue)
            ?? rawValue
    }

    private var sortName: String {
        Locale(identifier: AppLanguage.english.rawValue).localizedString(forIdentifier: rawValue)
            ?? displayName
    }

    var localeIdentifier: String? {
        switch supportedOrSystem {
        case .system: return nil
        default: return supportedOrSystem.rawValue
        }
    }

    /// Maps a BCP-47 or Apple locale identifier to a supported AppLanguage, if possible.
    static func from(localeIdentifier identifier: String) -> AppLanguage? {
        let lowercased = identifier.lowercased()

        // Direct match
        if let direct = supportedCases.first(where: { $0.rawValue.lowercased() == lowercased }) {
            return direct
        }

        // Language-only match (e.g. "pt_BR" -> "pt-BR", "zh-Hans-CN" -> "zh-Hans")
        let languageCode = lowercased.split(separator: "-").first
            ?? lowercased.split(separator: "_").first

        if let langCode = languageCode {
            let codeString = String(langCode)
            switch codeString {
            case "en": return .english
            case "ar": return .arabic
            case "zh":
                if lowercased.contains("hant") { return nil }
                return .chineseSimplified
            case "cs": return .czech
            case "da": return .danish
            case "nl": return .dutch
            case "fi": return .finnish
            case "fr": return .french
            case "de": return .german
            case "el": return .greek
            case "he", "iw": return .hebrew
            case "hi": return .hindi
            case "id", "in": return .indonesian
            case "it": return .italian
            case "ja": return .japanese
            case "ko": return .korean
            case "no", "nb": return .norwegian
            case "pl": return .polish
            case "pt": return .portugueseBrazil
            case "ru": return .russian
            case "es": return .spanish
            case "sv": return .swedish
            case "th": return .thai
            case "tr": return .turkish
            case "uk": return .ukrainian
            case "vi": return .vietnamese
            default: return nil
            }
        }

        return nil
    }
}

struct UserPreferencesSnapshot: Codable, Hashable {
    var appearanceMode: AppearanceMode
    var appLanguage: AppLanguage
    var includeMiddleName: Bool
    var strictMode: Bool
    var testOrder: [TestType]
    var hasSeenOnboarding: Bool

    static let `default` = UserPreferencesSnapshot(
        appearanceMode: .system,
        appLanguage: .system,
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
    var namifyNormalized: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    var namifyLettersOnly: String {
        unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init)
            .joined()
            .lowercased()
    }
}

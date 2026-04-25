import Foundation
import UIKit

struct RhymeVulnerabilityAnalyzer {
    let store: OfflineDatasetStore
    let language: AppLanguage

    init(store: OfflineDatasetStore, language: AppLanguage = .english) {
        self.store = store
        self.language = language.resolvedForAnalysis
    }

    func analyze(name: NameComponents) async -> TestResult {
        do {
            let patterns = try await store.rhymePatterns(for: language)
            let nameParts = [name.first, name.middle, name.last].compactMap { $0 }
            let rawMatches = nameParts.flatMap { part -> [RhymeFinding] in
                let normalized = part.namifyLettersOnly
                return patterns.flatMap { pattern -> [RhymeFinding] in
                    guard Self.matches(normalized, pattern: pattern) else { return [] }
                    return pattern.words.map { word in
                        RhymeFinding(source: part, rhyme: word.word, negative: word.negative, severity: word.severity)
                    }
                }
            }
            var seenMatches = Set<RhymeFinding>()
            let matches = rawMatches.filter { seenMatches.insert($0).inserted }

            let negative = matches.filter(\.negative)
            let severe = negative.contains(where: { $0.severity == "severe" || $0.severity == "critical" })
            let verdict: TestVerdict
            let summary: String

            switch (negative.count, severe) {
            case (0, _):
                verdict = .pass
                summary = L("rhyme.summary.none")
            case (1, false):
                verdict = .warn
                summary = L("rhyme.summary.one")
            default:
                verdict = .fail
                summary = String(format: L("rhyme.summary.multiple"), negative.count)
            }

            let detailText: String
            if matches.isEmpty {
                detailText = L("rhyme.detail.none")
            } else {
                detailText = String(format: L("rhyme.detail.some"), matches.first?.source ?? name.first)
            }

            return TestResult(
                testType: .rhyme,
                verdict: verdict,
                summaryLine: summary,
                detailText: detailText,
                detailData: .rhyme(RhymeDetail(findings: matches.prefix(6).map { $0 }, checkedPatterns: patterns.count))
            )
        } catch {
            return unavailableResult(for: .rhyme)
        }
    }

    private static func matches(_ normalized: String, pattern: RhymePatternRecord) -> Bool {
        let anchors = pattern.anchors.map(\.namifyLettersOnly).filter { $0.isEmpty == false }
        switch pattern.matchType {
        case "exact":
            return anchors.contains(normalized)
        default:
            return anchors.contains { normalized.hasSuffix($0) }
        }
    }
}

struct InitialsDetector {
    let store: OfflineDatasetStore
    let language: AppLanguage

    init(store: OfflineDatasetStore, language: AppLanguage = .english) {
        self.store = store
        self.language = language.resolvedForAnalysis
    }

    func analyze(name: NameComponents) async -> TestResult {
        do {
            let database = try await store.badInitials(for: language)
            let initials = computeInitials(for: name)
            let normalizedMatches = database.filter { record in
                initials.contains(record.initials.uppercased())
            }
            let primary = name.initials.replacingOccurrences(of: ".", with: "")

            let verdict: TestVerdict
            if normalizedMatches.isEmpty {
                verdict = .pass
            } else if normalizedMatches.contains(where: { $0.severity == "critical" || $0.initials == primary }) {
                verdict = .fail
            } else {
                verdict = .warn
            }

            let summary: String
            if normalizedMatches.isEmpty {
                summary = String(format: L("initials.summary.pass"), name.initials)
            } else if let match = normalizedMatches.first {
                summary = String(format: L("initials.summary.fail"), match.initials.chunkedInitials)
            } else {
                summary = String(format: L("initials.summary.warn"), name.initials)
            }

            let matches = normalizedMatches.map {
                InitialsMatch(initials: $0.initials.chunkedInitials, category: $0.category, severity: $0.severity, note: $0.note)
            }

            let detailText = normalizedMatches.isEmpty
                ? L("initials.detail.pass")
                : L("initials.detail.fail")

            return TestResult(
                testType: .initials,
                verdict: verdict,
                summaryLine: summary,
                detailText: detailText,
                detailData: .initials(
                    InitialsDetail(
                        initials: name.initials,
                        alternateInitials: initials.filter { $0 != primary }.map(\.chunkedInitials),
                        matches: matches
                    )
                )
            )
        } catch {
            return unavailableResult(for: .initials)
        }
    }

    private func computeInitials(for name: NameComponents) -> [String] {
        let first = String(name.first.prefix(1)).uppercased()
        let last = String(name.last.prefix(1)).uppercased()
        let middle = name.middle.map { String($0.prefix(1)).uppercased() }

        var values = Set<String>()
        values.insert(first + last)
        values.insert(last + first)
        if let middle {
            values.insert(first + middle + last)
            values.insert(last + middle + first)
            values.insert(middle + first)
            values.insert(middle + last)
            values.insert(last + middle)
            values.insert(first + middle)
        }
        return Array(values)
    }
}

struct PronunciationTester {
    let store: OfflineDatasetStore
    let language: AppLanguage

    init(store: OfflineDatasetStore, language: AppLanguage = .english) {
        self.store = store
        self.language = language.resolvedForAnalysis
    }

    func analyze(name: NameComponents) async -> TestResult {
        do {
            let rules = try await store.phoneticRules(for: language)
            let normalized = name.first.namifyLettersOnly
            let override = rules.overrides.first { $0.name.namifyNormalized == name.first.namifyNormalized }
            let matchedRules = rules.rules.filter { rule in
                let pattern = rule.pattern.namifyLettersOnly
                return pattern.isEmpty == false && normalized.contains(pattern)
            }
            let factors = matchedRules.map { rule in
                return PronunciationFactor(
                    label: rule.label,
                    explanation: rule.explanation,
                    verdict: TestVerdict(rawValue: rule.verdict) ?? .warn
                )
            }

            var score = 1 + matchedRules.reduce(0) { $0 + $1.penalty }
            if name.first.count > lengthWarningThreshold { score += 1 }
            if language == .english && name.first.contains(where: { "qxz".contains($0.lowercased()) }) { score += 1 }
            score = min(score, 10)

            let verdict: TestVerdict = score <= 3 ? .pass : (score <= 6 ? .warn : .fail)
            let summary: String = score <= 3
                ? L("pronunciation.summary.pass")
                : (score <= 6
                    ? L("pronunciation.summary.warn")
                    : L("pronunciation.summary.fail"))
            let phonetic = override?.phonetic ?? Self.naivePhonetic(for: name.first, language: language)
            let likely = override?.likelyMispronunciation ?? Self.defaultReading(for: name.first, language: language)

            let detailText = L("pronunciation.detail")

            return TestResult(
                testType: .pronunciation,
                verdict: verdict,
                summaryLine: summary,
                detailText: detailText,
                detailData: .pronunciation(
                    PronunciationDetail(
                        phonetic: phonetic,
                        likelyMispronunciation: likely,
                        difficultyScore: score,
                        factors: factors.isEmpty
                            ? [.init(label: L("pronunciation.factor.pass.label"), explanation: L("pronunciation.factor.pass.explanation"), verdict: .pass)]
                            : factors
                    )
                )
            )
        } catch {
            return unavailableResult(for: .pronunciation)
        }
    }

    private var lengthWarningThreshold: Int {
        switch language {
        case .chineseSimplified, .japanese, .korean:
            return 5
        case .thai:
            return 14
        default:
            return 10
        }
    }

    private static func naivePhonetic(for name: String, language: AppLanguage) -> String {
        guard language == .english else { return name }
        return name
            .replacingOccurrences(of: "ph", with: "f")
            .replacingOccurrences(of: "ie", with: "ee")
            .replacingOccurrences(of: "th", with: "th")
            .uppercased()
    }

    private static func defaultReading(for name: String, language: AppLanguage) -> String {
        language == .english ? name.uppercased() : name
    }
}

struct EmailSimulator {
    let store: OfflineDatasetStore
    let language: AppLanguage

    init(store: OfflineDatasetStore, language: AppLanguage = .english) {
        self.store = store
        self.language = language.resolvedForAnalysis
    }

    func analyze(name: NameComponents) async -> TestResult {
        do {
            let database = try await store.frequencyDatabase(for: language)
            let domains = try await store.domains()
            let firstRank = database.firstNames.first(where: { $0.name.namifyNormalized == name.first.namifyNormalized })?.rank ?? 5_000
            let lastRank = database.lastNames.first(where: { $0.name.namifyNormalized == name.last.namifyNormalized })?.rank ?? 8_000
            let availabilityIndex = firstRank + lastRank
            let variants = candidateAddresses(for: name).flatMap { candidate in
                domains.prefix(5).map { domain -> EmailVariant in
                    let score = availabilityScore(candidate: candidate, domain: domain, availabilityIndex: availabilityIndex)
                    return EmailVariant(value: candidate, domain: domain, status: score)
                }
            }

            let likelyAvailable = variants.filter { $0.status == "Likely Available" }.count
            let readability = readabilityScore(for: name)
            let verdict: TestVerdict
            if likelyAvailable >= 7 && readability == "EASY" {
                verdict = .pass
            } else if likelyAvailable <= 3 || readability == "DIFFICULT" {
                verdict = .fail
            } else {
                verdict = .warn
            }

            let summary: String
            switch verdict {
            case .pass:
                summary = L("email.summary.pass")
            case .warn:
                summary = L("email.summary.warn")
            case .fail:
                summary = L("email.summary.fail")
            }

            return TestResult(
                testType: .email,
                verdict: verdict,
                summaryLine: summary,
                detailText: L("email.detail"),
                detailData: .email(EmailDetail(variants: Array(variants.prefix(10)), readability: readability))
            )
        } catch {
            return unavailableResult(for: .email)
        }
    }

    private func candidateAddresses(for name: NameComponents) -> [String] {
        let first = name.first.namifyLettersOnly
        let last = name.last.namifyLettersOnly
        return [
            "\(first).\(last)",
            "\(first)\(last)",
            "\(first.prefix(1)).\(last)",
            "\(first).\(last.prefix(1))",
            "\(first.prefix(1))\(last)"
        ]
    }

    private func availabilityScore(candidate: String, domain: String, availabilityIndex: Int) -> String {
        let complexity = candidate.count + domain.count
        switch availabilityIndex + complexity {
        case ..<350:
            return "Likely Taken"
        case ..<2_500:
            return "Uncertain"
        default:
            return "Likely Available"
        }
    }

    private func readabilityScore(for name: NameComponents) -> String {
        var penalties = 0
        if name.fullName.count > 25 { penalties += 2 }
        if name.first.contains(where: { "qxz".contains($0.lowercased()) }) { penalties += 1 }
        if ["Sean", "Shawn", "Siobhan", "Niamh"].contains(name.first) { penalties += 1 }
        switch penalties {
        case ..<2: return "EASY"
        case 2...3: return "MODERATE"
        default: return "DIFFICULT"
        }
    }
}

struct NameTagPreviewGenerator {
    func analyze(name: NameComponents, includeMiddleName: Bool, language: AppLanguage = .english) async -> TestResult {
        let analysisLanguage = language.resolvedForAnalysis
        let displayName = includeMiddleName && name.middle != nil
            ? "\(name.first) \(String(name.middle!.prefix(1))). \(name.last)"
            : "\(name.first) \(name.last)"

        let width = (displayName as NSString).size(
            withAttributes: [.font: UIFont.systemFont(ofSize: 22, weight: .semibold)]
        ).width
        let hasDiacritics = displayName != displayName.folding(options: .diacriticInsensitive, locale: .current)
        let warnsForDiacritics = analysisLanguage == .english && hasDiacritics
        let charCount = displayName.count

        let verdict: TestVerdict
        let summary: String
        if charCount > 35 || width > 260 {
            verdict = .fail
            summary = L("nametag.summary.fail")
        } else if charCount > 25 || width > 220 || warnsForDiacritics || charCount <= 3 {
            verdict = .warn
            summary = L("nametag.summary.warn")
        } else {
            verdict = .pass
            summary = L("nametag.summary.pass")
        }

        return TestResult(
            testType: .nameTag,
            verdict: verdict,
            summaryLine: summary,
            detailText: L("nametag.detail"),
            detailData: .nameTag(NameTagDetail(displayName: displayName, characterCount: charCount, fitsScore: summary, warnsForDiacritics: warnsForDiacritics))
        )
    }
}

struct HistoricalNamesakeEngine {
    let store: OfflineDatasetStore
    let language: AppLanguage

    init(store: OfflineDatasetStore, language: AppLanguage = .english) {
        self.store = store
        self.language = language.resolvedForAnalysis
    }

    func analyze(name: NameComponents) async -> TestResult {
        do {
            let dataset = try await store.namesakes(for: language)
            let normalized = name.first.namifyNormalized
            let soundex = soundexCode(for: normalized)
            let matches = dataset
                .filter {
                    $0.firstName.namifyNormalized == normalized
                        || (language == .english && soundexCode(for: $0.firstName.namifyNormalized) == soundex)
                }
                .sorted { $0.notoriety < $1.notoriety }

            let limited = Array(matches.prefix(5))
            let hasFamousNegative = limited.contains { $0.sentiment == "negative" && $0.notoriety <= 100 }
            let negativeCount = limited.filter { $0.sentiment == "negative" }.count
            let verdict: TestVerdict
            if limited.isEmpty {
                verdict = .pass
            } else if hasFamousNegative || negativeCount > 1 {
                verdict = .fail
            } else if limited.contains(where: { $0.sentiment == "mixed" || $0.sentiment == "negative" }) {
                verdict = .warn
            } else {
                verdict = .pass
            }

            let summary: String
            switch verdict {
            case .pass:
                summary = limited.isEmpty ? L("namesake.summary.empty.pass") : L("namesake.summary.has.pass")
            case .warn:
                summary = L("namesake.summary.warn")
            case .fail:
                summary = L("namesake.summary.fail")
            }

            let detailText = limited.isEmpty
                ? L("namesake.detail.empty")
                : L("namesake.detail.some")

            return TestResult(
                testType: .namesake,
                verdict: verdict,
                summaryLine: summary,
                detailText: detailText,
                detailData: .namesake(
                    NamesakeDetail(
                        entries: limited.map {
                            NamesakeEntry(
                                fullName: $0.fullName,
                                shortBio: $0.shortBio,
                                era: $0.era,
                                domain: $0.domain,
                                sentiment: $0.sentiment
                            )
                        },
                        checkedCount: dataset.count
                    )
                )
            )
        } catch {
            return unavailableResult(for: .namesake)
        }
    }
}

struct MonogramAnalyzer {
    func analyze(name: NameComponents) async -> TestResult {
        let initials = name.monogramLetters
        if initials.allSatisfy(Self.isLatinInitial) == false {
            return scriptNeutralResult(initials: initials)
        }

        let symmetry = symmetryScore(for: initials)
        let width = widthScore(for: initials)
        let conflict = conflictScore(for: initials)
        let balance = curveBalanceScore(for: initials)
        let readability = readabilityScore(for: initials)
        let total = Int(round(symmetry + width + conflict + balance + readability))

        let verdict: TestVerdict = total >= 4 ? .pass : (total >= 2 ? .warn : .fail)
        let summary: String
        switch verdict {
        case .pass: summary = L("monogram.summary.pass")
        case .warn: summary = L("monogram.summary.warn")
        case .fail: summary = L("monogram.summary.fail")
        }

        return TestResult(
            testType: .monogram,
            verdict: verdict,
            summaryLine: summary,
            detailText: L("monogram.detail"),
            detailData: .monogram(
                MonogramDetail(
                    score: max(0, min(total, 5)),
                    symmetry: symmetry,
                    widthHarmony: width,
                    readability: readability,
                    previews: [
                        .init(title: "Classic", initials: initials),
                        .init(title: "Stacked", initials: initials),
                        .init(title: "Interleaved", initials: initials)
                    ]
                )
            )
        )
    }

    private func scriptNeutralResult(initials: [String]) -> TestResult {
        let uniqueCount = Set(initials).count
        let total = uniqueCount >= 2 ? 4 : 3
        let verdict: TestVerdict = total >= 4 ? .pass : .warn
        let summary: String
        switch verdict {
        case .pass: summary = L("monogram.summary.pass")
        case .warn: summary = L("monogram.summary.warn")
        case .fail: summary = L("monogram.summary.fail")
        }

        return TestResult(
            testType: .monogram,
            verdict: verdict,
            summaryLine: summary,
            detailText: L("monogram.detail"),
            detailData: .monogram(
                MonogramDetail(
                    score: total,
                    symmetry: uniqueCount >= 2 ? 1.0 : 0.5,
                    widthHarmony: 1.0,
                    readability: 1.0,
                    previews: [
                        .init(title: "Classic", initials: initials),
                        .init(title: "Stacked", initials: initials),
                        .init(title: "Interleaved", initials: initials)
                    ]
                )
            )
        )
    }

    private static func isLatinInitial(_ value: String) -> Bool {
        guard value.count == 1, let scalar = value.unicodeScalars.first else { return false }
        return (65...90).contains(Int(scalar.value))
    }

    private func symmetryScore(for initials: [String]) -> Double {
        let symmetric = Set(["A", "H", "I", "M", "O", "T", "U", "V", "W", "X", "Y"])
        let partial = Set(["B", "C", "D", "E", "K"])
        let average = initials.reduce(0.0) { partialResult, letter in
            if symmetric.contains(letter) { return partialResult + 1.0 }
            if partial.contains(letter) { return partialResult + 0.5 }
            return partialResult
        } / Double(initials.count)
        return average >= 0.6 ? 1.0 : 0.0
    }

    private func widthScore(for initials: [String]) -> Double {
        let narrow = Set(["I", "J", "L", "T"])
        let wide = Set(["M", "O", "Q", "W"])
        let categories = Set(initials.map { letter -> Int in
            if narrow.contains(letter) { return 0 }
            if wide.contains(letter) { return 2 }
            return 1
        })
        switch categories.count {
        case 1: return 1.0
        case 2: return 0.5
        default: return 0.0
        }
    }

    private func conflictScore(for initials: [String]) -> Double {
        let topConflicts = Set(["G", "J", "P", "Q", "Y"])
        let bottomConflicts = Set(["B", "D", "F", "H", "K", "L"])
        let firstConflict = topConflicts.contains(initials[0]) ? 1 : 0
        let secondConflict = bottomConflicts.contains(initials[2]) ? 1 : 0
        switch firstConflict + secondConflict {
        case 0: return 1.0
        case 1: return 0.5
        default: return 0.0
        }
    }

    private func curveBalanceScore(for initials: [String]) -> Double {
        let curved = Set(["B", "C", "D", "G", "J", "O", "P", "Q", "R", "S", "U"])
        let categories = Set(initials.map { curved.contains($0) ? 0 : 1 })
        return categories.count == 2 ? 1.0 : 0.5
    }

    private func readabilityScore(for initials: [String]) -> Double {
        let confusablePairs: Set<Set<String>> = [
            Set(["I", "L"]), Set(["O", "Q"]), Set(["V", "U"]), Set(["C", "G"])
        ]
        let pairCount = confusablePairs.reduce(0) { result, pair in
            result + (pair.isSubset(of: Set(initials)) ? 1 : 0)
        }
        switch pairCount {
        case 0: return 1.0
        case 1: return 0.5
        default: return 0.0
        }
    }
}

private func soundexCode(for string: String) -> String {
    guard let first = string.first else { return "" }
    let mapping: [Character: String] = [
        "b": "1", "f": "1", "p": "1", "v": "1",
        "c": "2", "g": "2", "j": "2", "k": "2", "q": "2", "s": "2", "x": "2", "z": "2",
        "d": "3", "t": "3",
        "l": "4",
        "m": "5", "n": "5",
        "r": "6"
    ]
    let tail = string.dropFirst().compactMap { mapping[$0] }.removingConsecutiveDuplicates()
    return (String(first).uppercased() + tail.joined()).padding(toLength: 4, withPad: "0", startingAt: 0)
}

private extension Array where Element: Equatable {
    func removingConsecutiveDuplicates() -> [Element] {
        reduce(into: []) { partial, element in
            if partial.last != element {
                partial.append(element)
            }
        }
    }
}

private extension String {
    var chunkedInitials: String {
        map(String.init).joined(separator: ".") + "."
    }
}

private func unavailableResult(for type: TestType) -> TestResult {
    TestResult(
        testType: type,
        verdict: .warn,
        summaryLine: L("generic.unavailable.summary"),
        detailText: L("generic.unavailable.detail"),
        detailData: .generic(message: L("generic.unavailable.message"))
    )
}

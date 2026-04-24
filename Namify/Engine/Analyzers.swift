import Foundation
import UIKit

struct RhymeVulnerabilityAnalyzer {
    let store: OfflineDatasetStore

    func analyze(name: NameComponents) async -> TestResult {
        do {
            let patterns = try await store.rhymePatterns()
            let normalized = name.first.namifyLettersOnly
            let matches = patterns.flatMap { pattern -> [RhymeFinding] in
                guard pattern.anchors.contains(where: { normalized.hasSuffix($0) }) else { return [] }
                return pattern.words.map { word in
                    RhymeFinding(source: name.first, rhyme: word.word, negative: word.negative, severity: word.severity)
                }
            }

            let negative = matches.filter(\.negative)
            let severe = negative.contains(where: { $0.severity == "severe" || $0.severity == "critical" })
            let verdict: TestVerdict
            let summary: String

            switch (negative.count, severe) {
            case (0, _):
                verdict = .pass
                summary = String(localized: "rhyme.summary.none")
            case (1, false):
                verdict = .warn
                summary = String(localized: "rhyme.summary.one")
            default:
                verdict = .fail
                summary = String(format: String(localized: "rhyme.summary.multiple"), negative.count)
            }

            let detailText: String
            if matches.isEmpty {
                detailText = String(localized: "rhyme.detail.none")
            } else {
                detailText = String(format: String(localized: "rhyme.detail.some"), name.first)
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
}

struct InitialsDetector {
    let store: OfflineDatasetStore

    func analyze(name: NameComponents) async -> TestResult {
        do {
            let database = try await store.badInitials()
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
                summary = String(format: String(localized: "initials.summary.pass"), name.initials)
            } else if let match = normalizedMatches.first {
                summary = String(format: String(localized: "initials.summary.fail"), match.initials.chunkedInitials)
            } else {
                summary = String(format: String(localized: "initials.summary.warn"), name.initials)
            }

            let matches = normalizedMatches.map {
                InitialsMatch(initials: $0.initials.chunkedInitials, category: $0.category, severity: $0.severity, note: $0.note)
            }

            let detailText = normalizedMatches.isEmpty
                ? String(localized: "initials.detail.pass")
                : String(localized: "initials.detail.fail")

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

    func analyze(name: NameComponents) async -> TestResult {
        do {
            let rules = try await store.phoneticRules()
            let normalized = name.first.namifyLettersOnly
            let override = rules.overrides.first { $0.name.namifyNormalized == name.first.namifyNormalized }
            let factors = rules.rules.compactMap { rule -> PronunciationFactor? in
                guard normalized.contains(rule.pattern.lowercased()) else { return nil }
                let labelKey = Self.localizedKey(forPattern: rule.pattern)
                return PronunciationFactor(
                    label: String(localized: String.LocalizationValue(labelKey)),
                    explanation: String(localized: String.LocalizationValue("\(labelKey).explanation")),
                    verdict: TestVerdict(rawValue: rule.verdict) ?? .warn
                )
            }

            var score = 1 + factors.reduce(0) { $0 + penalty(for: $1.verdict) }
            if name.first.count > 10 { score += 1 }
            if name.first.contains(where: { "qxz".contains($0.lowercased()) }) { score += 1 }
            score = min(score, 10)

            let verdict: TestVerdict = score <= 3 ? .pass : (score <= 6 ? .warn : .fail)
            let summary: String = score <= 3
                ? String(localized: "pronunciation.summary.pass")
                : (score <= 6
                    ? String(localized: "pronunciation.summary.warn")
                    : String(localized: "pronunciation.summary.fail"))
            let phonetic = override?.phonetic ?? Self.naivePhonetic(for: name.first)
            let likely = override?.likelyMispronunciation ?? Self.englishDefault(for: name.first)

            let detailText = String(localized: "pronunciation.detail")

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
                            ? [.init(label: String(localized: "pronunciation.factor.pass.label"), explanation: String(localized: "pronunciation.factor.pass.explanation"), verdict: .pass)]
                            : factors
                    )
                )
            )
        } catch {
            return unavailableResult(for: .pronunciation)
        }
    }

    private static func localizedKey(forPattern pattern: String) -> String {
        switch pattern {
        case "gh": return "pronunciation.rule.silentLetters"
        case "bh": return "pronunciation.rule.uncommonCombo"
        case "ao": return "pronunciation.rule.ambiguousVowel"
        case "eigh": return "pronunciation.rule.eigh"
        case "sz": return "pronunciation.rule.sz"
        case "x": return "pronunciation.rule.uncommonFreq"
        default: return "pronunciation.rule.uncommonCombo"
        }
    }

    private func penalty(for verdict: TestVerdict) -> Int {
        switch verdict {
        case .pass: 0
        case .warn: 1
        case .fail: 2
        }
    }

    private static func naivePhonetic(for name: String) -> String {
        name
            .replacingOccurrences(of: "ph", with: "f")
            .replacingOccurrences(of: "ie", with: "ee")
            .replacingOccurrences(of: "th", with: "th")
            .uppercased()
    }

    private static func englishDefault(for name: String) -> String {
        name.uppercased()
    }
}

struct EmailSimulator {
    let store: OfflineDatasetStore

    func analyze(name: NameComponents) async -> TestResult {
        do {
            let database = try await store.frequencyDatabase()
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
                summary = String(localized: "email.summary.pass")
            case .warn:
                summary = String(localized: "email.summary.warn")
            case .fail:
                summary = String(localized: "email.summary.fail")
            }

            return TestResult(
                testType: .email,
                verdict: verdict,
                summaryLine: summary,
                detailText: String(localized: "email.detail"),
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
    func analyze(name: NameComponents, includeMiddleName: Bool) async -> TestResult {
        let displayName = includeMiddleName && name.middle != nil
            ? "\(name.first) \(String(name.middle!.prefix(1))). \(name.last)"
            : "\(name.first) \(name.last)"

        let width = (displayName as NSString).size(
            withAttributes: [.font: UIFont.systemFont(ofSize: 22, weight: .semibold)]
        ).width
        let hasDiacritics = displayName != displayName.folding(options: .diacriticInsensitive, locale: .current)
        let charCount = displayName.count

        let verdict: TestVerdict
        let summary: String
        if charCount > 35 || width > 260 {
            verdict = .fail
            summary = String(localized: "nametag.summary.fail")
        } else if charCount > 25 || width > 220 || hasDiacritics || charCount <= 3 {
            verdict = .warn
            summary = String(localized: "nametag.summary.warn")
        } else {
            verdict = .pass
            summary = String(localized: "nametag.summary.pass")
        }

        return TestResult(
            testType: .nameTag,
            verdict: verdict,
            summaryLine: summary,
            detailText: String(localized: "nametag.detail"),
            detailData: .nameTag(NameTagDetail(displayName: displayName, characterCount: charCount, fitsScore: summary, warnsForDiacritics: hasDiacritics))
        )
    }
}

struct HistoricalNamesakeEngine {
    let store: OfflineDatasetStore

    func analyze(name: NameComponents) async -> TestResult {
        do {
            let dataset = try await store.namesakes()
            let normalized = name.first.namifyNormalized
            let soundex = soundexCode(for: normalized)
            let matches = dataset
                .filter {
                    $0.firstName.namifyNormalized == normalized
                        || soundexCode(for: $0.firstName.namifyNormalized) == soundex
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
                summary = limited.isEmpty ? String(localized: "namesake.summary.empty.pass") : String(localized: "namesake.summary.has.pass")
            case .warn:
                summary = String(localized: "namesake.summary.warn")
            case .fail:
                summary = String(localized: "namesake.summary.fail")
            }

            let detailText = limited.isEmpty
                ? String(localized: "namesake.detail.empty")
                : String(localized: "namesake.detail.some")

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
        let symmetry = symmetryScore(for: initials)
        let width = widthScore(for: initials)
        let conflict = conflictScore(for: initials)
        let balance = curveBalanceScore(for: initials)
        let readability = readabilityScore(for: initials)
        let total = Int(round(symmetry + width + conflict + balance + readability))

        let verdict: TestVerdict = total >= 4 ? .pass : (total >= 2 ? .warn : .fail)
        let summary: String
        switch verdict {
        case .pass: summary = String(localized: "monogram.summary.pass")
        case .warn: summary = String(localized: "monogram.summary.warn")
        case .fail: summary = String(localized: "monogram.summary.fail")
        }

        return TestResult(
            testType: .monogram,
            verdict: verdict,
            summaryLine: summary,
            detailText: String(localized: "monogram.detail"),
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
        summaryLine: String(localized: "generic.unavailable.summary"),
        detailText: String(localized: "generic.unavailable.detail"),
        detailData: .generic(message: String(localized: "generic.unavailable.message"))
    )
}

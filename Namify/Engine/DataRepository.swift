import Foundation

struct RhymePatternRecord: Codable, Hashable {
    struct WordRecord: Codable, Hashable {
        let word: String
        let negative: Bool
        let severity: String?
    }

    let language: String?
    let sound: String
    let anchors: [String]
    let matchType: String?
    let words: [WordRecord]

    init(
        language: String? = AppLanguage.english.rawValue,
        sound: String,
        anchors: [String],
        matchType: String? = nil,
        words: [WordRecord]
    ) {
        self.language = language
        self.sound = sound
        self.anchors = anchors
        self.matchType = matchType
        self.words = words
    }
}

struct RhymeDatabase: Codable {
    let patterns: [RhymePatternRecord]
}

struct BadInitialsRecord: Codable, Hashable {
    let language: String?
    let initials: String
    let category: String
    let severity: String
    let note: String

    init(
        language: String? = AppLanguage.english.rawValue,
        initials: String,
        category: String,
        severity: String,
        note: String
    ) {
        self.language = language
        self.initials = initials
        self.category = category
        self.severity = severity
        self.note = note
    }
}

struct BadInitialsDatabase: Codable {
    let flagged: [BadInitialsRecord]
}

struct PronunciationRuleRecord: Codable, Hashable {
    let language: String?
    let pattern: String
    let label: String
    let penalty: Int
    let explanation: String
    let verdict: String

    init(
        language: String? = AppLanguage.english.rawValue,
        pattern: String,
        label: String,
        penalty: Int,
        explanation: String,
        verdict: String
    ) {
        self.language = language
        self.pattern = pattern
        self.label = label
        self.penalty = penalty
        self.explanation = explanation
        self.verdict = verdict
    }
}

struct PronunciationOverrideRecord: Codable, Hashable {
    let language: String?
    let name: String
    let phonetic: String
    let likelyMispronunciation: String

    init(
        language: String? = AppLanguage.english.rawValue,
        name: String,
        phonetic: String,
        likelyMispronunciation: String
    ) {
        self.language = language
        self.name = name
        self.phonetic = phonetic
        self.likelyMispronunciation = likelyMispronunciation
    }
}

struct PhoneticRuleDatabase: Codable {
    let rules: [PronunciationRuleRecord]
    let overrides: [PronunciationOverrideRecord]
}

struct FrequencyEntry: Codable, Hashable {
    let language: String?
    let name: String
    let rank: Int

    init(language: String? = AppLanguage.english.rawValue, name: String, rank: Int) {
        self.language = language
        self.name = name
        self.rank = rank
    }
}

struct FrequencyDatabase: Codable {
    let firstNames: [FrequencyEntry]
    let lastNames: [FrequencyEntry]
}

struct HistoricalNamesakeRecord: Codable, Hashable {
    let language: String?
    let firstName: String
    let fullName: String
    let shortBio: String
    let era: String
    let domain: String
    let sentiment: String
    let notoriety: Int

    init(
        language: String? = AppLanguage.english.rawValue,
        firstName: String,
        fullName: String,
        shortBio: String,
        era: String,
        domain: String,
        sentiment: String,
        notoriety: Int
    ) {
        self.language = language
        self.firstName = firstName
        self.fullName = fullName
        self.shortBio = shortBio
        self.era = era
        self.domain = domain
        self.sentiment = sentiment
        self.notoriety = notoriety
    }
}

struct HistoricalNamesakeDatabase: Codable {
    let entries: [HistoricalNamesakeRecord]
}

struct EmailDomainDatabase: Codable {
    let domains: [String]
}

actor OfflineDatasetStore {
    static let shared = OfflineDatasetStore()

    private var rhymeCache: [RhymePatternRecord]?
    private var initialsCache: [BadInitialsRecord]?
    private var pronunciationCache: PhoneticRuleDatabase?
    private var frequencyCache: FrequencyDatabase?
    private var namesakeCache: [HistoricalNamesakeRecord]?
    private var domainsCache: [String]?

    func rhymePatterns() throws -> [RhymePatternRecord] {
        if let rhymeCache { return rhymeCache }
        let decoded = (try? decode(RhymeDatabase.self, file: "rhyme_patterns"))?.patterns ?? SeedData.rhymePatterns
        rhymeCache = decoded
        return decoded
    }

    func rhymePatterns(for language: AppLanguage) throws -> [RhymePatternRecord] {
        localizedRecords(try rhymePatterns(), for: language, language: \.language)
    }

    func badInitials() throws -> [BadInitialsRecord] {
        if let initialsCache { return initialsCache }
        let decoded = (try? decode(BadInitialsDatabase.self, file: "bad_initials"))?.flagged ?? SeedData.badInitials
        initialsCache = decoded
        return decoded
    }

    func badInitials(for language: AppLanguage) throws -> [BadInitialsRecord] {
        localizedRecords(try badInitials(), for: language, language: \.language)
    }

    func phoneticRules() throws -> PhoneticRuleDatabase {
        if let pronunciationCache { return pronunciationCache }
        let decoded = (try? decode(PhoneticRuleDatabase.self, file: "phonetic_rules")) ?? SeedData.phoneticRules
        pronunciationCache = decoded
        return decoded
    }

    func phoneticRules(for language: AppLanguage) throws -> PhoneticRuleDatabase {
        let database = try phoneticRules()
        return PhoneticRuleDatabase(
            rules: localizedRecords(database.rules, for: language, language: \.language),
            overrides: localizedRecords(database.overrides, for: language, language: \.language, fallbackToEnglish: false)
        )
    }

    func frequencyDatabase() throws -> FrequencyDatabase {
        if let frequencyCache { return frequencyCache }
        let decoded = (try? decode(FrequencyDatabase.self, file: "popular_names_frequency")) ?? SeedData.frequencyDatabase
        frequencyCache = decoded
        return decoded
    }

    func frequencyDatabase(for language: AppLanguage) throws -> FrequencyDatabase {
        let database = try frequencyDatabase()
        return FrequencyDatabase(
            firstNames: localizedRecords(database.firstNames, for: language, language: \.language),
            lastNames: localizedRecords(database.lastNames, for: language, language: \.language)
        )
    }

    func namesakes() throws -> [HistoricalNamesakeRecord] {
        if let namesakeCache { return namesakeCache }
        let decoded = (try? decode(HistoricalNamesakeDatabase.self, file: "historical_namesakes"))?.entries ?? SeedData.namesakes
        namesakeCache = decoded
        return decoded
    }

    func namesakes(for language: AppLanguage) throws -> [HistoricalNamesakeRecord] {
        localizedRecords(try namesakes(), for: language, language: \.language)
    }

    func domains() throws -> [String] {
        if let domainsCache { return domainsCache }
        let decoded = (try? decode(EmailDomainDatabase.self, file: "common_email_domains"))?.domains ?? SeedData.domains
        domainsCache = decoded
        return decoded
    }

    private func decode<T: Decodable>(_ type: T.Type, file: String) throws -> T {
        let url = Bundle.namifyResources.url(forResource: file, withExtension: "json", subdirectory: "Data")
            ?? Bundle.namifyResources.url(forResource: file, withExtension: "json")

        guard let url else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }

    private func localizedRecords<Record>(
        _ records: [Record],
        for language: AppLanguage,
        language keyPath: KeyPath<Record, String?>,
        fallbackToEnglish: Bool = true
    ) -> [Record] {
        let resolvedLanguage = language.resolvedForAnalysis
        let localized = records.filter { $0[keyPath: keyPath] == resolvedLanguage.rawValue }
        if localized.isEmpty == false {
            return localized
        }

        guard fallbackToEnglish else { return [] }
        let english = records.filter { ($0[keyPath: keyPath] ?? AppLanguage.english.rawValue) == AppLanguage.english.rawValue }
        return english.isEmpty ? records : english
    }
}

private enum SeedData {
    static let rhymePatterns: [RhymePatternRecord] = [
        .init(sound: "AYDEN", anchors: ["aiden", "ayden", "aden"], words: [.init(word: "maiden", negative: false, severity: nil), .init(word: "raiden", negative: false, severity: nil)]),
        .init(sound: "ART", anchors: ["art", "hart", "bart", "mart"], words: [.init(word: "fart", negative: true, severity: "moderate"), .init(word: "tart", negative: true, severity: "mild"), .init(word: "cart", negative: false, severity: nil)]),
        .init(sound: "ASH", anchors: ["ash"], words: [.init(word: "trash", negative: true, severity: "moderate"), .init(word: "rash", negative: false, severity: nil)]),
        .init(sound: "ELLA", anchors: ["ella", "ela"], words: [.init(word: "stella", negative: false, severity: nil), .init(word: "mozzarella", negative: false, severity: nil)]),
        .init(sound: "IAN", anchors: ["ian", "ien"], words: [.init(word: "pee-an", negative: true, severity: "mild"), .init(word: "dean", negative: false, severity: nil)]),
        .init(sound: "LEE", anchors: ["lee", "li", "leigh", "ley"], words: [.init(word: "flea", negative: true, severity: "mild"), .init(word: "glee", negative: false, severity: nil)]),
        .init(sound: "UNA", anchors: ["una", "oona"], words: [.init(word: "tuna", negative: false, severity: nil), .init(word: "luna", negative: false, severity: nil)]),
        .init(sound: "OE", anchors: ["joe", "jo"], words: [.init(word: "blow", negative: true, severity: "mild"), .init(word: "foe", negative: true, severity: "moderate")])
    ]

    static let badInitials: [BadInitialsRecord] = [
        .init(initials: "ASS", category: "profanity", severity: "critical", note: "Common profanity"),
        .init(initials: "STD", category: "embarrassing", severity: "moderate", note: "Medical acronym with social baggage"),
        .init(initials: "BJ", category: "embarrassing", severity: "moderate", note: "Suggestive abbreviation"),
        .init(initials: "KKK", category: "culturally_insensitive", severity: "critical", note: "Hate-group reference"),
        .init(initials: "BAD", category: "playground", severity: "mild", note: "Negative plain-English word"),
        .init(initials: "BUM", category: "bathroom_humor", severity: "mild", note: "Common teasing target"),
        .init(initials: "POO", category: "bathroom_humor", severity: "critical", note: "Common teasing target"),
        .init(initials: "WTF", category: "slang", severity: "moderate", note: "Profane slang acronym")
    ]

    static let phoneticRules = PhoneticRuleDatabase(
        rules: [
            .init(pattern: "gh", label: "Silent letters", penalty: 1, explanation: "Contains a gh sequence that English speakers often guess wrong.", verdict: "warn"),
            .init(pattern: "bh", label: "Uncommon letter combination", penalty: 2, explanation: "Contains a Gaelic-style consonant blend that many readers will not parse correctly.", verdict: "fail"),
            .init(pattern: "ao", label: "Ambiguous vowel cluster", penalty: 2, explanation: "Two-vowel cluster with multiple likely readings.", verdict: "warn"),
            .init(pattern: "eigh", label: "Ambiguous vowel cluster", penalty: 2, explanation: "EIGH patterns produce multiple English guesses.", verdict: "warn"),
            .init(pattern: "sz", label: "Uncommon letter combination", penalty: 2, explanation: "SZ is uncommon in English-first names and often causes hesitation.", verdict: "fail"),
            .init(pattern: "x", label: "Uncommon letter frequency", penalty: 1, explanation: "X in the middle of a given name increases dictation friction.", verdict: "warn")
        ],
        overrides: [
            .init(name: "Siobhan", phonetic: "shih-VAWN", likelyMispronunciation: "see-OH-ban"),
            .init(name: "Niamh", phonetic: "NEEV", likelyMispronunciation: "nee-AM-h"),
            .init(name: "Aoife", phonetic: "EE-fa", likelyMispronunciation: "AY-oh-fee"),
            .init(name: "Sean", phonetic: "SHAWN", likelyMispronunciation: "SEEN"),
            .init(name: "Calliope", phonetic: "kuh-LIE-oh-pee", likelyMispronunciation: "CALL-ee-ope")
        ]
    )

    static let frequencyDatabase = FrequencyDatabase(
        firstNames: [
            .init(name: "James", rank: 4), .init(name: "Mary", rank: 7), .init(name: "John", rank: 1), .init(name: "Emma", rank: 2),
            .init(name: "Olivia", rank: 1), .init(name: "Liam", rank: 1), .init(name: "Noah", rank: 2), .init(name: "Charlotte", rank: 3),
            .init(name: "Sophia", rank: 5), .init(name: "Ava", rank: 6), .init(name: "Mason", rank: 11), .init(name: "Eleanor", rank: 32),
            .init(name: "Siobhan", rank: 890), .init(name: "Niamh", rank: 1320), .init(name: "Aoife", rank: 1460), .init(name: "Atlas", rank: 124),
            .init(name: "Attila", rank: 4100), .init(name: "Cleo", rank: 702), .init(name: "Wolf", rank: 2890), .init(name: "Ada", rank: 211),
            .init(name: "Ulysses", rank: 1830), .init(name: "Sloane", rank: 181), .init(name: "Zelda", rank: 610), .init(name: "Lucian", rank: 431)
        ],
        lastNames: [
            .init(name: "Smith", rank: 1), .init(name: "Johnson", rank: 2), .init(name: "Brown", rank: 4), .init(name: "Williams", rank: 3),
            .init(name: "Gallagher", rank: 765), .init(name: "Moriarty", rank: 2040), .init(name: "Wren", rank: 7301), .init(name: "Blackwood", rank: 9820),
            .init(name: "Stone", rank: 120), .init(name: "Caldwell", rank: 1504), .init(name: "Hawthorne", rank: 2660), .init(name: "Nguyen", rank: 38),
            .init(name: "Cruz", rank: 87), .init(name: "Patel", rank: 57), .init(name: "Volkov", rank: 14500), .init(name: "Sokolov", rank: 13100)
        ]
    )

    static let namesakes: [HistoricalNamesakeRecord] = [
        .init(firstName: "Ada", fullName: "Ada Lovelace", shortBio: "Pioneer of computer programming.", era: "19th century", domain: "science", sentiment: "positive", notoriety: 12),
        .init(firstName: "Attila", fullName: "Attila the Hun", shortBio: "Conquering ruler of the Huns.", era: "5th century", domain: "politics", sentiment: "negative", notoriety: 40),
        .init(firstName: "Cleo", fullName: "Cleopatra", shortBio: "Last active ruler of Ptolemaic Egypt.", era: "1st century BCE", domain: "politics", sentiment: "mixed", notoriety: 25),
        .init(firstName: "James", fullName: "James Baldwin", shortBio: "American writer and civil-rights thinker.", era: "20th century", domain: "arts", sentiment: "positive", notoriety: 55),
        .init(firstName: "James", fullName: "James Dean", shortBio: "American actor and cultural icon.", era: "20th century", domain: "arts", sentiment: "positive", notoriety: 61),
        .init(firstName: "John", fullName: "John Wayne Gacy", shortBio: "Serial killer and criminal.", era: "20th century", domain: "crime", sentiment: "negative", notoriety: 19),
        .init(firstName: "John", fullName: "John Lennon", shortBio: "Musician and cultural figure.", era: "20th century", domain: "arts", sentiment: "positive", notoriety: 11),
        .init(firstName: "Mary", fullName: "Mary Shelley", shortBio: "Author of Frankenstein.", era: "19th century", domain: "arts", sentiment: "positive", notoriety: 33),
        .init(firstName: "Mary", fullName: "Bloody Mary", shortBio: "English queen with violent legacy.", era: "16th century", domain: "politics", sentiment: "negative", notoriety: 80),
        .init(firstName: "Adolf", fullName: "Adolf Hitler", shortBio: "Dictator of Nazi Germany.", era: "20th century", domain: "politics", sentiment: "negative", notoriety: 1),
        .init(firstName: "Ulysses", fullName: "Ulysses S. Grant", shortBio: "US president and Civil War general.", era: "19th century", domain: "politics", sentiment: "positive", notoriety: 52),
        .init(firstName: "Wolf", fullName: "Wolf Blitzer", shortBio: "American broadcast journalist.", era: "21st century", domain: "media", sentiment: "neutral", notoriety: 450),
        .init(firstName: "Zelda", fullName: "Zelda Fitzgerald", shortBio: "American socialite and writer.", era: "20th century", domain: "arts", sentiment: "mixed", notoriety: 280)
    ]

    static let domains = ["gmail.com", "outlook.com", "yahoo.com", "icloud.com", "proton.me"]
}

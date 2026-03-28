import Foundation

struct RhymeFinding: Codable, Hashable {
    let source: String
    let rhyme: String
    let negative: Bool
    let severity: String?
}

struct RhymeDetail: Codable, Hashable {
    let findings: [RhymeFinding]
    let checkedPatterns: Int
}

struct InitialsMatch: Codable, Hashable {
    let initials: String
    let category: String
    let severity: String
    let note: String
}

struct InitialsDetail: Codable, Hashable {
    let initials: String
    let alternateInitials: [String]
    let matches: [InitialsMatch]
}

struct PronunciationFactor: Codable, Hashable {
    let label: String
    let explanation: String
    let verdict: TestVerdict
}

struct PronunciationDetail: Codable, Hashable {
    let phonetic: String
    let likelyMispronunciation: String
    let difficultyScore: Int
    let factors: [PronunciationFactor]
}

struct EmailVariant: Codable, Hashable {
    let value: String
    let domain: String
    let status: String
}

struct EmailDetail: Codable, Hashable {
    let variants: [EmailVariant]
    let readability: String
}

struct NameTagDetail: Codable, Hashable {
    let displayName: String
    let characterCount: Int
    let fitsScore: String
    let warnsForDiacritics: Bool
}

struct NamesakeEntry: Codable, Hashable, Identifiable {
    var id: String { fullName + era }
    let fullName: String
    let shortBio: String
    let era: String
    let domain: String
    let sentiment: String
}

struct NamesakeDetail: Codable, Hashable {
    let entries: [NamesakeEntry]
    let checkedCount: Int
}

struct MonogramStylePreview: Codable, Hashable {
    let title: String
    let initials: [String]
}

struct MonogramDetail: Codable, Hashable {
    let score: Int
    let symmetry: Double
    let widthHarmony: Double
    let readability: Double
    let previews: [MonogramStylePreview]
}

enum TestDetailData: Codable, Hashable {
    case rhyme(RhymeDetail)
    case initials(InitialsDetail)
    case pronunciation(PronunciationDetail)
    case email(EmailDetail)
    case nameTag(NameTagDetail)
    case namesake(NamesakeDetail)
    case monogram(MonogramDetail)
    case generic(message: String)

    private enum CodingKeys: String, CodingKey {
        case kind
        case payload
        case message
    }

    private enum Kind: String, Codable {
        case rhyme
        case initials
        case pronunciation
        case email
        case nameTag
        case namesake
        case monogram
        case generic
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .rhyme:
            self = .rhyme(try container.decode(RhymeDetail.self, forKey: .payload))
        case .initials:
            self = .initials(try container.decode(InitialsDetail.self, forKey: .payload))
        case .pronunciation:
            self = .pronunciation(try container.decode(PronunciationDetail.self, forKey: .payload))
        case .email:
            self = .email(try container.decode(EmailDetail.self, forKey: .payload))
        case .nameTag:
            self = .nameTag(try container.decode(NameTagDetail.self, forKey: .payload))
        case .namesake:
            self = .namesake(try container.decode(NamesakeDetail.self, forKey: .payload))
        case .monogram:
            self = .monogram(try container.decode(MonogramDetail.self, forKey: .payload))
        case .generic:
            self = .generic(message: try container.decode(String.self, forKey: .message))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .rhyme(let payload):
            try container.encode(Kind.rhyme, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .initials(let payload):
            try container.encode(Kind.initials, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .pronunciation(let payload):
            try container.encode(Kind.pronunciation, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .email(let payload):
            try container.encode(Kind.email, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .nameTag(let payload):
            try container.encode(Kind.nameTag, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .namesake(let payload):
            try container.encode(Kind.namesake, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .monogram(let payload):
            try container.encode(Kind.monogram, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .generic(let message):
            try container.encode(Kind.generic, forKey: .kind)
            try container.encode(message, forKey: .message)
        }
    }
}

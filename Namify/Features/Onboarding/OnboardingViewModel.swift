import SwiftUI
import SwiftData

struct OnboardingGoal: Identifiable, Hashable {
    let id: String
    let emoji: String
    let title: String
    let subtitle: String

    static func == (lhs: OnboardingGoal, rhs: OnboardingGoal) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct OnboardingPainPoint: Identifiable, Hashable {
    let id: String
    let emoji: String
    let title: String

    static func == (lhs: OnboardingPainPoint, rhs: OnboardingPainPoint) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Testimonial: Identifiable {
    let id = UUID()
    let name: String
    let tag: String
    let text: String
    let rating: Int
}

struct OnboardingTestimonialNames {
    let parentOne: String
    let parentTwo: String
    let parentThree: String
    let flaggedName: String
    let chosenName: String
    let pronunciationName: String

    static var current: OnboardingTestimonialNames {
        names(for: AppLocalization.currentLanguage.resolvedForSuggestions)
    }

    static func names(for language: AppLanguage) -> OnboardingTestimonialNames {
        namesByLanguage[language.resolvedForSuggestions] ?? namesByLanguage[.english]!
    }

    func localizedText(_ text: String) -> String {
        var localized = text
        for source in ["Olivia S.:ksi", "Olivia S.", "Olivia S", "أوليفيا س.", "オリビア・S", "오리비아 S."] {
            localized = localized.replacingOccurrences(of: source, with: flaggedName)
        }
        for source in ["Theosta", "Theo'ya", "Theo", "ثيو", "テオ", "Θοδωρή"] {
            localized = localized.replacingOccurrences(of: source, with: chosenName)
        }
        for source in ["Arjun", "أرجون", "アルジュン", "아르준", "Αρτζούν"] {
            localized = localized.replacingOccurrences(of: source, with: pronunciationName)
        }
        return localized
    }

    private static let namesByLanguage: [AppLanguage: OnboardingTestimonialNames] = [
        .english: .init(parentOne: "Sarah M.", parentTwo: "James T.", parentThree: "Priya K.", flaggedName: "Olivia S.", chosenName: "Theo", pronunciationName: "Arjun"),
        .arabic: .init(parentOne: "سارة م.", parentTwo: "يوسف ت.", parentThree: "مريم ك.", flaggedName: "ليان س.", chosenName: "آدم", pronunciationName: "عمر"),
        .chineseSimplified: .init(parentOne: "李娜", parentTwo: "王伟", parentThree: "陈婷", flaggedName: "梓萱", chosenName: "浩然", pronunciationName: "子涵"),
        .czech: .init(parentOne: "Anna M.", parentTwo: "Jakub T.", parentThree: "Tereza K.", flaggedName: "Eliška S.", chosenName: "Matěj", pronunciationName: "Tomáš"),
        .danish: .init(parentOne: "Emma M.", parentTwo: "William T.", parentThree: "Freja K.", flaggedName: "Alma S.", chosenName: "Oscar", pronunciationName: "Aksel"),
        .dutch: .init(parentOne: "Emma M.", parentTwo: "Daan T.", parentThree: "Mila K.", flaggedName: "Julia S.", chosenName: "Bram", pronunciationName: "Sem"),
        .finnish: .init(parentOne: "Aino M.", parentTwo: "Eino T.", parentThree: "Venla K.", flaggedName: "Eevi S.", chosenName: "Onni", pronunciationName: "Väinö"),
        .french: .init(parentOne: "Camille M.", parentTwo: "Louis T.", parentThree: "Léa K.", flaggedName: "Louise S.", chosenName: "Gabriel", pronunciationName: "Raphaël"),
        .german: .init(parentOne: "Emilia M.", parentTwo: "Leon T.", parentThree: "Hannah K.", flaggedName: "Mia S.", chosenName: "Matteo", pronunciationName: "Elias"),
        .greek: .init(parentOne: "Μαρία Μ.", parentTwo: "Νίκος Τ.", parentThree: "Ελένη Κ.", flaggedName: "Σοφία Σ.", chosenName: "Αλέξανδρος", pronunciationName: "Δημήτρης"),
        .hebrew: .init(parentOne: "נועה מ.", parentTwo: "איתן ט.", parentThree: "תמר ק.", flaggedName: "מאיה ס.", chosenName: "דניאל", pronunciationName: "יונתן"),
        .hindi: .init(parentOne: "आन्या म.", parentTwo: "आरव ट.", parentThree: "मीरा क.", flaggedName: "सिया स.", chosenName: "विवान", pronunciationName: "अर्जुन"),
        .indonesian: .init(parentOne: "Siti M.", parentTwo: "Rizky T.", parentThree: "Alya K.", flaggedName: "Nabila S.", chosenName: "Bima", pronunciationName: "Raka"),
        .italian: .init(parentOne: "Sofia M.", parentTwo: "Leonardo T.", parentThree: "Giulia K.", flaggedName: "Aurora S.", chosenName: "Lorenzo", pronunciationName: "Alessandro"),
        .japanese: .init(parentOne: "美咲 M", parentTwo: "大和 T", parentThree: "凛 K", flaggedName: "結菜", chosenName: "陽翔", pronunciationName: "蓮"),
        .korean: .init(parentOne: "서연 M.", parentTwo: "민준 T.", parentThree: "지우 K.", flaggedName: "서아", chosenName: "도윤", pronunciationName: "하윤"),
        .malay: .init(parentOne: "Aisyah M.", parentTwo: "Irfan T.", parentThree: "Hana K.", flaggedName: "Sofia S.", chosenName: "Danish", pronunciationName: "Zafran"),
        .norwegian: .init(parentOne: "Nora M.", parentTwo: "Jakob T.", parentThree: "Emma K.", flaggedName: "Sofie S.", chosenName: "Aksel", pronunciationName: "Emil"),
        .polish: .init(parentOne: "Zofia M.", parentTwo: "Antoni T.", parentThree: "Hanna K.", flaggedName: "Maja S.", chosenName: "Jan", pronunciationName: "Aleksander"),
        .portugueseBrazil: .init(parentOne: "Helena M.", parentTwo: "Miguel T.", parentThree: "Laura K.", flaggedName: "Alice S.", chosenName: "Arthur", pronunciationName: "Gabriel"),
        .russian: .init(parentOne: "Анна М.", parentTwo: "Дмитрий Т.", parentThree: "Мария К.", flaggedName: "София С.", chosenName: "Матвей", pronunciationName: "Артём"),
        .spanish: .init(parentOne: "Lucía M.", parentTwo: "Mateo T.", parentThree: "Camila K.", flaggedName: "Sofía S.", chosenName: "Martín", pronunciationName: "Nicolás"),
        .swedish: .init(parentOne: "Alice M.", parentTwo: "William T.", parentThree: "Maja K.", flaggedName: "Elsa S.", chosenName: "Hugo", pronunciationName: "Elias"),
        .thai: .init(parentOne: "คุณมิน", parentTwo: "คุณกันต์", parentThree: "คุณแพรว", flaggedName: "น้องพิม", chosenName: "น้องภีม", pronunciationName: "น้องฟ้า"),
        .turkish: .init(parentOne: "Zeynep M.", parentTwo: "Yusuf T.", parentThree: "Elif K.", flaggedName: "Defne S.", chosenName: "Eymen", pronunciationName: "Emir"),
        .ukrainian: .init(parentOne: "Софія М.", parentTwo: "Дмитро Т.", parentThree: "Анна К.", flaggedName: "Марія С.", chosenName: "Артем", pronunciationName: "Матвій"),
        .vietnamese: .init(parentOne: "Linh M.", parentTwo: "Minh T.", parentThree: "Trang K.", flaggedName: "Mai S.", chosenName: "An", pronunciationName: "Huy")
    ]
}

struct SolutionMapping: Identifiable {
    let id: String
    let painPoint: String
    let solution: String
    let icon: String
    let color: Color
}

enum NavigationDirection {
    case forward
    case backward
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var navigationDirection: NavigationDirection = .forward
    @Published var selectedGoal: OnboardingGoal?
    @Published var selectedPainPoints: Set<OnboardingPainPoint> = []
    @Published var selectedTests: Set<TestType> = Set(TestType.defaultOrder)
    @Published var demoName: NameComponents?
    @Published var demoSummary: NameRunSummary?
    @Published var isRunningDemo = false

    var goals: [OnboardingGoal] {
        [
            OnboardingGoal(id: "soundsBeautiful", emoji: "🎭", title: L("onboarding.goal.soundsBeautiful"), subtitle: L("onboarding.goal.soundsBeautiful.sub")),
            OnboardingGoal(id: "bullyProof", emoji: "🛡️", title: L("onboarding.goal.bullyProof"), subtitle: L("onboarding.goal.bullyProof.sub")),
            OnboardingGoal(id: "looksGood", emoji: "🏷️", title: L("onboarding.goal.looksGood"), subtitle: L("onboarding.goal.looksGood.sub")),
            OnboardingGoal(id: "goodHistory", emoji: "📚", title: L("onboarding.goal.goodHistory"), subtitle: L("onboarding.goal.goodHistory.sub")),
            OnboardingGoal(id: "easyPronounce", emoji: "🗣️", title: L("onboarding.goal.easyPronounce"), subtitle: L("onboarding.goal.easyPronounce.sub")),
            OnboardingGoal(id: "aesthetic", emoji: "🎨", title: L("onboarding.goal.aesthetic"), subtitle: L("onboarding.goal.aesthetic.sub")),
        ]
    }

    var painPoints: [OnboardingPainPoint] {
        [
            OnboardingPainPoint(id: "initials", emoji: "😰", title: L("onboarding.pain.initials")),
            OnboardingPainPoint(id: "rhymes", emoji: "😬", title: L("onboarding.pain.rhymes")),
            OnboardingPainPoint(id: "mispronunciation", emoji: "🤷", title: L("onboarding.pain.mispronunciation")),
            OnboardingPainPoint(id: "namesake", emoji: "👤", title: L("onboarding.pain.namesake")),
            OnboardingPainPoint(id: "family", emoji: "💬", title: L("onboarding.pain.family")),
            OnboardingPainPoint(id: "secondGuessing", emoji: "😵‍💫", title: L("onboarding.pain.secondGuessing")),
        ]
    }

    var testimonials: [Testimonial] {
        let names = OnboardingTestimonialNames.current
        return [
            Testimonial(name: names.parentOne, tag: L("onboarding.testimonial.1.tag"), text: names.localizedText(L("onboarding.testimonial.1.text")), rating: 5),
            Testimonial(name: names.parentTwo, tag: L("onboarding.testimonial.2.tag"), text: names.localizedText(L("onboarding.testimonial.2.text")), rating: 5),
            Testimonial(name: names.parentThree, tag: L("onboarding.testimonial.3.tag"), text: names.localizedText(L("onboarding.testimonial.3.text")), rating: 5),
        ]
    }

    var progressFraction: Double {
        currentStep.progressFraction
    }

    var canAdvance: Bool {
        switch currentStep {
        case .welcome: return true
        case .goal: return selectedGoal != nil
        case .painPoints: return !selectedPainPoints.isEmpty
        case .socialProof: return true
        case .solution: return true
        case .preferences: return !selectedTests.isEmpty
        case .processing: return false
        case .demoInput: return demoName != nil
        case .demoResults: return false
        }
    }

    func advance() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        navigationDirection = .forward
        withAnimation(NamifyMotion.smooth) {
            currentStep = next
        }
    }

    func goBack() {
        guard let previous = OnboardingStep(rawValue: currentStep.rawValue - 1),
              currentStep.canGoBack else { return }
        navigationDirection = .backward
        withAnimation(NamifyMotion.smooth) {
            currentStep = previous
        }
    }

    func runDemo(name: NameComponents) async -> NameRunSummary? {
        let engine = NameTestEngine()
        let preferences = UserPreferencesSnapshot(
            appearanceMode: .system,
            appLanguage: .system,
            includeMiddleName: true,
            strictMode: false,
            testOrder: TestType.defaultOrder.filter { selectedTests.contains($0) },
            hasSeenOnboarding: false
        )
        do {
            var finalSummary: NameRunSummary?
            for try await event in engine.run(name: name, preferences: preferences) {
                if case .completed(let summary) = event {
                    finalSummary = summary
                }
            }
            return finalSummary
        } catch {
            return nil
        }
    }

    func solutionMappings() -> [SolutionMapping] {
        let allMappings: [String: SolutionMapping] = [
            "initials": SolutionMapping(
                id: "initials",
                painPoint: L("onboarding.pain.initials"),
                solution: L("onboarding.solution.initials"),
                icon: "textformat.abc",
                color: Brand.initials
            ),
            "rhymes": SolutionMapping(
                id: "rhymes",
                painPoint: L("onboarding.pain.rhymes"),
                solution: L("onboarding.solution.rhymes"),
                icon: "music.note.list",
                color: Brand.rhyme
            ),
            "mispronunciation": SolutionMapping(
                id: "mispronunciation",
                painPoint: L("onboarding.pain.mispronunciation"),
                solution: L("onboarding.solution.pronunciation"),
                icon: "waveform.and.person.filled",
                color: Brand.pronunciation
            ),
            "namesake": SolutionMapping(
                id: "namesake",
                painPoint: L("onboarding.pain.namesake"),
                solution: L("onboarding.solution.namesake"),
                icon: "book.closed.fill",
                color: Brand.namesake
            ),
            "family": SolutionMapping(
                id: "family",
                painPoint: L("onboarding.pain.family"),
                solution: L("onboarding.solution.family"),
                icon: "shield.checkered",
                color: Brand.accent
            ),
            "secondGuessing": SolutionMapping(
                id: "secondGuessing",
                painPoint: L("onboarding.pain.secondGuessing"),
                solution: L("onboarding.solution.secondGuessing"),
                icon: "arrow.left.arrow.right",
                color: Brand.pass
            ),
        ]

        return selectedPainPoints.compactMap { allMappings[$0.id] }
    }
}

import SwiftUI
import SwiftData

struct OnboardingGoal: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let title: String
    let subtitle: String
}

struct OnboardingPainPoint: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let title: String
}

struct Testimonial: Identifiable {
    let id = UUID()
    let name: String
    let tag: String
    let text: String
    let rating: Int
}

struct SwipeCardItem: Identifiable, Hashable {
    let id = UUID()
    let text: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SwipeCardItem, rhs: SwipeCardItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct SolutionMapping: Identifiable {
    let id = UUID()
    let painPoint: String
    let solution: String
    let icon: String
    let color: Color
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var selectedGoal: OnboardingGoal?
    @Published var selectedPainPoints: Set<OnboardingPainPoint> = []
    @Published var swipedCards: [SwipeCardItem: Bool] = [:]
    @Published var selectedTests: Set<TestType> = Set(TestType.defaultOrder)
    @Published var demoName: NameComponents?
    @Published var demoSummary: NameRunSummary?
    @Published var isRunningDemo = false

    let goals: [OnboardingGoal] = [
        OnboardingGoal(emoji: "🎭", title: "Sounds beautiful", subtitle: "When spoken aloud"),
        OnboardingGoal(emoji: "🛡️", title: "Bully-proof", subtitle: "No playground teasing"),
        OnboardingGoal(emoji: "📧", title: "Email-friendly", subtitle: "Clean, professional address"),
        OnboardingGoal(emoji: "🏷️", title: "Looks good on paper", subtitle: "Resumes, diplomas, forms"),
        OnboardingGoal(emoji: "📚", title: "Good history", subtitle: "Positive namesake connections"),
        OnboardingGoal(emoji: "🗣️", title: "Easy to pronounce", subtitle: "No daily corrections"),
        OnboardingGoal(emoji: "🎨", title: "Aesthetic monogram", subtitle: "Beautiful initials"),
    ]

    let painPoints: [OnboardingPainPoint] = [
        OnboardingPainPoint(emoji: "😰", title: "Embarrassing initials"),
        OnboardingPainPoint(emoji: "😬", title: "Playground rhymes and teasing"),
        OnboardingPainPoint(emoji: "🤷", title: "Constant mispronunciation"),
        OnboardingPainPoint(emoji: "📧", title: "Awkward email address"),
        OnboardingPainPoint(emoji: "👤", title: "Namesake baggage"),
        OnboardingPainPoint(emoji: "💬", title: "Family pressure and judgement"),
        OnboardingPainPoint(emoji: "😵‍💫", title: "Second-guessing myself"),
    ]

    let testimonials: [Testimonial] = [
        Testimonial(name: "Sarah M.", tag: "First-time mom", text: "We almost named our daughter Olivia S. until Litmus flagged the initials. We caught it in time!", rating: 5),
        Testimonial(name: "James T.", tag: "Dad of three", text: "Tested 12 names before settling on Theo. The rhyme check saved us from a total disaster.", rating: 5),
        Testimonial(name: "Priya K.", tag: "Expecting", text: "I was worried about pronunciation. Litmus confirmed my instinct — Arjun is perfect.", rating: 5),
    ]

    let swipeCardItems: [SwipeCardItem] = [
        SwipeCardItem(text: "I spend hours on baby name lists but still feel completely unsure."),
        SwipeCardItem(text: "I'm terrified of accidental initials like A.S.S. or P.I.G."),
        SwipeCardItem(text: "I worry my child will be teased because of their name."),
        SwipeCardItem(text: "I can't stop imagining awkward email addresses."),
        SwipeCardItem(text: "What if there's a famous criminal with the same name?"),
    ]

    var progressFraction: Double {
        currentStep.progressFraction
    }

    var canAdvance: Bool {
        switch currentStep {
        case .welcome: return true
        case .goal: return selectedGoal != nil
        case .painPoints: return !selectedPainPoints.isEmpty
        case .socialProof: return true
        case .swipeCards: return true
        case .solution: return true
        case .preferences: return !selectedTests.isEmpty
        case .processing: return false
        case .demoInput: return demoName != nil
        case .demoResults: return false
        }
    }

    func advance() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(LitmusMotion.smooth) {
            currentStep = next
        }
    }

    func goBack() {
        guard let previous = OnboardingStep(rawValue: currentStep.rawValue - 1),
              currentStep.canGoBack else { return }
        withAnimation(LitmusMotion.smooth) {
            currentStep = previous
        }
    }

    func runDemo(name: NameComponents) async -> NameRunSummary? {
        let engine = NameTestEngine()
        let preferences = UserPreferencesSnapshot(
            appearanceMode: .system,
            includeMiddleName: true,
            strictMode: false,
            testOrder: Array(selectedTests),
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
            "Embarrassing initials": SolutionMapping(
                painPoint: "Embarrassing initials",
                solution: "Initials Check scans 500+ flagged combinations instantly",
                icon: "textformat.abc",
                color: Brand.initials
            ),
            "Playground rhymes and teasing": SolutionMapping(
                painPoint: "Playground rhymes",
                solution: "Rhyme Vulnerability detects 2,000+ risky rhymes and sounds",
                icon: "music.note.list",
                color: Brand.rhyme
            ),
            "Constant mispronunciation": SolutionMapping(
                painPoint: "Mispronunciation",
                solution: "Pronunciation Test scores difficulty and predicts mistakes",
                icon: "waveform.and.person.filled",
                color: Brand.pronunciation
            ),
            "Awkward email address": SolutionMapping(
                painPoint: "Awkward emails",
                solution: "Email Simulator shows how the address looks and reads",
                icon: "envelope.badge.shield.half.filled",
                color: Brand.email
            ),
            "Namesake baggage": SolutionMapping(
                painPoint: "Namesake baggage",
                solution: "Historical Namesake flags famous figures — good and bad",
                icon: "book.closed.fill",
                color: Brand.namesake
            ),
            "Family pressure and judgement": SolutionMapping(
                painPoint: "Family pressure",
                solution: "A data-backed report card gives you confidence to defend your choice",
                icon: "shield.checkered",
                color: Brand.accent
            ),
            "Second-guessing myself": SolutionMapping(
                painPoint: "Second-guessing",
                solution: "Test unlimited names and compare results side-by-side",
                icon: "arrow.left.arrow.right",
                color: Brand.pass
            ),
        ]

        return selectedPainPoints.compactMap { allMappings[$0.title] }
    }
}

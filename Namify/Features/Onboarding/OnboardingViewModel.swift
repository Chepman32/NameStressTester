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

struct SolutionMapping: Identifiable {
    let id: String
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
        [
            Testimonial(name: L("onboarding.testimonial.1.name"), tag: L("onboarding.testimonial.1.tag"), text: L("onboarding.testimonial.1.text"), rating: 5),
            Testimonial(name: L("onboarding.testimonial.2.name"), tag: L("onboarding.testimonial.2.tag"), text: L("onboarding.testimonial.2.text"), rating: 5),
            Testimonial(name: L("onboarding.testimonial.3.name"), tag: L("onboarding.testimonial.3.tag"), text: L("onboarding.testimonial.3.text"), rating: 5),
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
        withAnimation(NamifyMotion.smooth) {
            currentStep = next
        }
    }

    func goBack() {
        guard let previous = OnboardingStep(rawValue: currentStep.rawValue - 1),
              currentStep.canGoBack else { return }
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

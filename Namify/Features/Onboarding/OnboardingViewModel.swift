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
    @Published var selectedTests: Set<TestType> = Set(TestType.defaultOrder)
    @Published var demoName: NameComponents?
    @Published var demoSummary: NameRunSummary?
    @Published var isRunningDemo = false

    var goals: [OnboardingGoal] {
        [
            OnboardingGoal(emoji: "🎭", title: String(localized: "onboarding.goal.soundsBeautiful"), subtitle: String(localized: "onboarding.goal.soundsBeautiful.sub")),
            OnboardingGoal(emoji: "🛡️", title: String(localized: "onboarding.goal.bullyProof"), subtitle: String(localized: "onboarding.goal.bullyProof.sub")),
            OnboardingGoal(emoji: "🏷️", title: String(localized: "onboarding.goal.looksGood"), subtitle: String(localized: "onboarding.goal.looksGood.sub")),
            OnboardingGoal(emoji: "📚", title: String(localized: "onboarding.goal.goodHistory"), subtitle: String(localized: "onboarding.goal.goodHistory.sub")),
            OnboardingGoal(emoji: "🗣️", title: String(localized: "onboarding.goal.easyPronounce"), subtitle: String(localized: "onboarding.goal.easyPronounce.sub")),
            OnboardingGoal(emoji: "🎨", title: String(localized: "onboarding.goal.aesthetic"), subtitle: String(localized: "onboarding.goal.aesthetic.sub")),
        ]
    }

    var painPoints: [OnboardingPainPoint] {
        [
            OnboardingPainPoint(emoji: "😰", title: String(localized: "onboarding.pain.initials")),
            OnboardingPainPoint(emoji: "😬", title: String(localized: "onboarding.pain.rhymes")),
            OnboardingPainPoint(emoji: "🤷", title: String(localized: "onboarding.pain.mispronunciation")),
            OnboardingPainPoint(emoji: "👤", title: String(localized: "onboarding.pain.namesake")),
            OnboardingPainPoint(emoji: "💬", title: String(localized: "onboarding.pain.family")),
            OnboardingPainPoint(emoji: "😵‍💫", title: String(localized: "onboarding.pain.secondGuessing")),
        ]
    }

    var testimonials: [Testimonial] {
        [
            Testimonial(name: String(localized: "onboarding.testimonial.1.name"), tag: String(localized: "onboarding.testimonial.1.tag"), text: String(localized: "onboarding.testimonial.1.text"), rating: 5),
            Testimonial(name: String(localized: "onboarding.testimonial.2.name"), tag: String(localized: "onboarding.testimonial.2.tag"), text: String(localized: "onboarding.testimonial.2.text"), rating: 5),
            Testimonial(name: String(localized: "onboarding.testimonial.3.name"), tag: String(localized: "onboarding.testimonial.3.tag"), text: String(localized: "onboarding.testimonial.3.text"), rating: 5),
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
            String(localized: "onboarding.pain.initials"): SolutionMapping(
                painPoint: String(localized: "onboarding.pain.initials"),
                solution: String(localized: "onboarding.solution.initials"),
                icon: "textformat.abc",
                color: Brand.initials
            ),
            String(localized: "onboarding.pain.rhymes"): SolutionMapping(
                painPoint: String(localized: "onboarding.pain.rhymes"),
                solution: String(localized: "onboarding.solution.rhymes"),
                icon: "music.note.list",
                color: Brand.rhyme
            ),
            String(localized: "onboarding.pain.mispronunciation"): SolutionMapping(
                painPoint: String(localized: "onboarding.pain.mispronunciation"),
                solution: String(localized: "onboarding.solution.pronunciation"),
                icon: "waveform.and.person.filled",
                color: Brand.pronunciation
            ),
            String(localized: "onboarding.pain.namesake"): SolutionMapping(
                painPoint: String(localized: "onboarding.pain.namesake"),
                solution: String(localized: "onboarding.solution.namesake"),
                icon: "book.closed.fill",
                color: Brand.namesake
            ),
            String(localized: "onboarding.pain.family"): SolutionMapping(
                painPoint: String(localized: "onboarding.pain.family"),
                solution: String(localized: "onboarding.solution.family"),
                icon: "shield.checkered",
                color: Brand.accent
            ),
            String(localized: "onboarding.pain.secondGuessing"): SolutionMapping(
                painPoint: String(localized: "onboarding.pain.secondGuessing"),
                solution: String(localized: "onboarding.solution.secondGuessing"),
                icon: "arrow.left.arrow.right",
                color: Brand.pass
            ),
        ]

        return selectedPainPoints.compactMap { allMappings[$0.title] }
    }
}

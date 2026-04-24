import Foundation

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case goal
    case painPoints
    case socialProof
    case solution
    case preferences
    case processing
    case demoInput
    case demoResults

    var progressFraction: Double {
        let total = Double(Self.allCases.count - 1)
        return total > 0 ? Double(rawValue) / total : 0
    }

    var canGoBack: Bool {
        rawValue > 0 && self != .processing && self != .demoResults
    }

    var canSkip: Bool {
        self != .processing && self != .demoResults
    }
}

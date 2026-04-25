import XCTest
@testable import Namify

final class NamifyEngineTests: XCTestCase {
    func testOverallVerdictTreatsWarnAsPassOutsideStrictMode() {
        let results: [TestResult] = [
            .init(testType: .rhyme, verdict: .pass, summaryLine: "", detailText: "", detailData: .generic(message: "")),
            .init(testType: .initials, verdict: .warn, summaryLine: "", detailText: "", detailData: .generic(message: "")),
            .init(testType: .pronunciation, verdict: .warn, summaryLine: "", detailText: "", detailData: .generic(message: "")),
            .init(testType: .email, verdict: .pass, summaryLine: "", detailText: "", detailData: .generic(message: "")),
            .init(testType: .nameTag, verdict: .pass, summaryLine: "", detailText: "", detailData: .generic(message: "")),
            .init(testType: .namesake, verdict: .fail, summaryLine: "", detailText: "", detailData: .generic(message: "")),
            .init(testType: .monogram, verdict: .warn, summaryLine: "", detailText: "", detailData: .generic(message: ""))
        ]

        XCTAssertEqual(OverallVerdict.from(results: results, strictMode: false), .survived)
        XCTAssertEqual(OverallVerdict.from(results: results, strictMode: true), .mixed)
    }

    func testInitialsDetectorFlagsPrimaryMatch() async {
        let result = await InitialsDetector(store: .shared).analyze(name: NameComponents(first: "A", middle: "S", last: "S"))
        XCTAssertEqual(result.verdict, .fail)
    }

    func testMonogramAnalyzerRewardsBalancedInitials() async {
        let pass = await MonogramAnalyzer().analyze(name: NameComponents(first: "Ada", middle: "Mae", last: "Wren"))
        XCTAssertEqual(pass.verdict, .pass)
    }

    func testNameReportRoundTrip() {
        let name = NameComponents(first: "Ada", middle: "Mae", last: "Wren")
        let result = TestResult(testType: .rhyme, verdict: .pass, summaryLine: "OK", detailText: "Fine", detailData: .generic(message: "none"))
        let report = NameReport(
            name: name,
            testDate: .now,
            overallVerdict: .survived,
            passCount: 1,
            warnCount: 0,
            failCount: 0,
            testResults: [result]
        )
        XCTAssertEqual(report.testResults.first?.summaryLine, "OK")
        XCTAssertEqual(report.fullName, "Ada Mae Wren")
    }

    func testPreferencesDefaultMissingOrUnsupportedLanguageToSystem() {
        let preferences = UserPreferences()

        preferences.appLanguageRaw = nil
        XCTAssertEqual(preferences.snapshot.appLanguage, .system)

        preferences.appLanguageRaw = AppLanguage.hungarian.rawValue
        XCTAssertEqual(preferences.snapshot.appLanguage, .system)
    }

    func testPreferencesPersistSupportedLanguage() {
        let preferences = UserPreferences()
        var snapshot = UserPreferencesSnapshot.default
        snapshot.appLanguage = .russian

        preferences.apply(snapshot)

        XCTAssertEqual(preferences.appLanguageRaw, AppLanguage.russian.rawValue)
        XCTAssertEqual(preferences.snapshot.appLanguage, .russian)
    }

    func testLanguagePickerCasesAreAlphabetizedWithSystemFirst() {
        let expectedSupportedCases: [AppLanguage] = [
            .arabic,
            .chineseSimplified,
            .czech,
            .danish,
            .dutch,
            .english,
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

        XCTAssertEqual(AppLanguage.supportedCases, expectedSupportedCases)
        XCTAssertEqual(AppLanguage.selectableCases, [.system] + expectedSupportedCases)
    }

    func testLocalizedNameSuggestionsMatchSelectedLanguage() {
        let russianSuggestions = LocalizedNameSuggestions.names(for: .russian)

        XCTAssertFalse(russianSuggestions.isEmpty)
        XCTAssertTrue(
            russianSuggestions.allSatisfy { suggestion in
                suggestion.unicodeScalars.contains { scalar in
                    (0x0400...0x04FF).contains(Int(scalar.value))
                }
            }
        )
    }

    func testAsianNameSuggestionsUseLocalScripts() {
        let scriptChecks: [(AppLanguage, ClosedRange<Int>)] = [
            (.chineseSimplified, 0x4E00...0x9FFF),
            (.japanese, 0x3040...0x9FFF),
            (.korean, 0xAC00...0xD7AF),
            (.thai, 0x0E00...0x0E7F)
        ]

        for (language, range) in scriptChecks {
            let suggestions = LocalizedNameSuggestions.names(for: language)
            XCTAssertFalse(suggestions.isEmpty)
            XCTAssertTrue(
                suggestions.allSatisfy { suggestion in
                    suggestion.unicodeScalars.contains { scalar in
                        range.contains(Int(scalar.value))
                    }
                },
                "Expected localized suggestions for \(language.rawValue)"
            )
        }
    }

    func testMalayNameSuggestionsAreLocalized() {
        let suggestions = Set(LocalizedNameSuggestions.names(for: .malay))

        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertFalse(suggestions.isDisjoint(with: ["Aisyah", "Muhammad", "Siti", "Zafran"]))
    }

    func testSystemNameSuggestionResolverUsesPreferredLanguageIdentifiers() {
        XCTAssertEqual(AppLanguage.suggestionLanguage(from: ["ru", "en-US"]), .russian)
        XCTAssertEqual(AppLanguage.suggestionLanguage(from: ["zh-Hans-CN", "en-US"]), .chineseSimplified)
        XCTAssertEqual(AppLanguage.suggestionLanguage(from: ["ja-JP", "en-US"]), .japanese)
        XCTAssertEqual(AppLanguage.suggestionLanguage(from: ["ko-KR", "en-US"]), .korean)
        XCTAssertEqual(AppLanguage.suggestionLanguage(from: ["th-TH", "en-US"]), .thai)
        XCTAssertEqual(AppLanguage.suggestionLanguage(from: ["ms-MY", "en-US"]), .malay)
    }

    @MainActor
    func testOnboardingTestimonialsLocalizeExampleNames() {
        AppLocalization.setLanguage(.russian)
        let testimonials = OnboardingViewModel().testimonials
        let combinedText = testimonials.map { "\($0.name) \($0.text)" }.joined(separator: " ")

        XCTAssertEqual(testimonials[0].name, "Анна М.")
        XCTAssertTrue(combinedText.contains("София С."))
        XCTAssertTrue(combinedText.contains("Матвей"))
        XCTAssertTrue(combinedText.contains("Артём"))
        XCTAssertFalse(combinedText.contains("Olivia"))
        XCTAssertFalse(combinedText.contains("Theo"))
        XCTAssertFalse(combinedText.contains("Arjun"))

        AppLocalization.setLanguage(.system)
    }

    func testOnboardingAsianExampleNamesUseLocalScripts() {
        let checks: [(AppLanguage, String, String)] = [
            (.chineseSimplified, "梓萱", "浩然"),
            (.japanese, "結菜", "陽翔"),
            (.korean, "서아", "도윤"),
            (.thai, "น้องพิม", "น้องภีม")
        ]

        for (language, flaggedName, chosenName) in checks {
            let names = OnboardingTestimonialNames.names(for: language)
            let text = names.localizedText("Olivia S. Theo Arjun")

            XCTAssertTrue(text.contains(flaggedName))
            XCTAssertTrue(text.contains(chosenName))
            XCTAssertFalse(text.contains("Olivia"))
            XCTAssertFalse(text.contains("Theo"))
            XCTAssertFalse(text.contains("Arjun"))
        }
    }

    func testOnboardingSkipIsHiddenForTransientSteps() {
        XCTAssertTrue(OnboardingStep.welcome.canSkip)
        XCTAssertTrue(OnboardingStep.demoInput.canSkip)
        XCTAssertFalse(OnboardingStep.processing.canSkip)
        XCTAssertFalse(OnboardingStep.demoResults.canSkip)
    }

    @MainActor
    func testOnboardingChoiceIdentitySurvivesRecomputedOptions() {
        let viewModel = OnboardingViewModel()

        let selectedGoal = viewModel.goals[0]
        viewModel.selectedGoal = selectedGoal
        XCTAssertEqual(viewModel.selectedGoal?.id, viewModel.goals[0].id)

        let selectedPainPoint = viewModel.painPoints[0]
        viewModel.selectedPainPoints.insert(selectedPainPoint)
        XCTAssertTrue(viewModel.selectedPainPoints.contains(viewModel.painPoints[0]))
        XCTAssertEqual(viewModel.solutionMappings().first?.id, selectedPainPoint.id)
    }

    func testAppLocalizationUsesSelectedLanguage() {
        AppLocalization.setLanguage(.english)
        XCTAssertEqual(L("settings.title"), "Settings")
        XCTAssertEqual(L("onboarding.skip"), "Skip")

        AppLocalization.setLanguage(.russian)
        XCTAssertEqual(L("settings.title"), "Настройки")
        XCTAssertEqual(L("onboarding.skip"), "Пропустить")

        AppLocalization.setLanguage(.system)
    }
}

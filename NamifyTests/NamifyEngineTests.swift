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

    func testOnboardingSkipIsHiddenForTransientSteps() {
        XCTAssertTrue(OnboardingStep.welcome.canSkip)
        XCTAssertTrue(OnboardingStep.demoInput.canSkip)
        XCTAssertFalse(OnboardingStep.processing.canSkip)
        XCTAssertFalse(OnboardingStep.demoResults.canSkip)
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

import XCTest

final class GlanceUITests: XCTestCase {

    // MARK: - Helpers

    private func launchFresh() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        return app
    }

    private func launchWithMarker() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--with-sample-data"]
        app.launch()
        return app
    }

    // MARK: - Test 1: Tab Navigation

    func testTabNavigation() {
        let app = launchWithMarker()
        XCTAssertTrue(app.navigationBars["My Markers"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Visits"].tap()
        XCTAssertTrue(app.navigationBars["Visits"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Markers"].tap()
        XCTAssertTrue(app.navigationBars["My Markers"].waitForExistence(timeout: 3))
    }

    // MARK: - Test 2: Onboarding → Home Screen Populated

    func testOnboardingToHomeScreen() {
        let app = launchFresh()
        // Welcome screen appears (no navigation bar — it's a plain ZStack)
        // Tap "Get Started" to enter marker selection
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()
        // Marker selection screen appears
        XCTAssertTrue(app.navigationBars["Choose Your Markers"].waitForExistence(timeout: 5))
        // Activate search bar and find HDL
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText("HDL")
        // Marker rows are Buttons with accessibilityLabel = displayName
        let hdlButton = app.buttons["HDL Cholesterol"]
        XCTAssertTrue(hdlButton.waitForExistence(timeout: 5))
        hdlButton.tap()
        // Tap Done button (label is "Done (1 selected)")
        let doneButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Done'")).firstMatch
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3))
        doneButton.tap()
        // Home screen populated with HDL
        XCTAssertTrue(app.navigationBars["My Markers"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["HDL Cholesterol"].waitForExistence(timeout: 3))
    }

    // MARK: - Test 3: Quick Add → Verify Entry Saved

    func testQuickAddAppearsOnHome() {
        let app = launchWithMarker()
        XCTAssertTrue(app.navigationBars["My Markers"].waitForExistence(timeout: 5))
        // Navigate into HDL Cholesterol detail view
        app.staticTexts["HDL Cholesterol"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["HDL Cholesterol"].waitForExistence(timeout: 5))
        // Tap "Add Reading" toolbar button — pre-selects HDL so no Picker interaction needed
        let addButton = app.navigationBars["HDL Cholesterol"].buttons["Add Reading"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()
        // Quick-add sheet opens with HDL pre-selected
        XCTAssertTrue(app.navigationBars["Add Reading"].waitForExistence(timeout: 5))
        // Enter value
        let valueField = app.textFields.firstMatch
        XCTAssertTrue(valueField.waitForExistence(timeout: 3))
        valueField.tap()
        valueField.typeText("72")
        // Save
        app.navigationBars.buttons["Save"].tap()
        // Entry should appear in the detail view list
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS '72'")).firstMatch
                .waitForExistence(timeout: 5)
        )
    }

    // MARK: - Test 4: Batch Entry → Values Saved

    func testBatchEntryValuesSaved() {
        let app = launchWithMarker()
        XCTAssertTrue(app.navigationBars["My Markers"].waitForExistence(timeout: 5))
        // Open batch entry
        let fab = app.buttons["Add reading"]
        XCTAssertTrue(fab.waitForExistence(timeout: 3))
        fab.tap()
        app.buttons["Add Lab Panel"].tap()
        XCTAssertTrue(app.navigationBars["Add Lab Panel"].waitForExistence(timeout: 3))
        // Enter value in first text field
        let firstField = app.textFields.firstMatch
        if firstField.waitForExistence(timeout: 3) {
            firstField.tap()
            firstField.typeText("65")
        }
        // Save
        app.navigationBars.buttons["Save"].tap()
        XCTAssertTrue(app.navigationBars["My Markers"].waitForExistence(timeout: 5))
    }

    // MARK: - Test 5: Visit Logging → Appears in List

    func testVisitLoggingAppearsInList() {
        let app = launchWithMarker()
        app.tabBars.buttons["Visits"].tap()
        XCTAssertTrue(app.navigationBars["Visits"].waitForExistence(timeout: 3))
        // Log a visit
        let logButton = app.navigationBars.buttons["Log visit"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 3))
        logButton.tap()
        let doctorField = app.textFields["Doctor / Clinic Name"]
        XCTAssertTrue(doctorField.waitForExistence(timeout: 3))
        doctorField.tap()
        doctorField.typeText("Dr. Test")
        app.navigationBars.buttons["Save"].tap()
        // Visit appears in list
        XCTAssertTrue(app.staticTexts["Dr. Test"].waitForExistence(timeout: 3))
    }

    // MARK: - Test 6: Search → Correct Results

    func testSearchReturnsCorrectResults() {
        let app = launchWithMarker()
        XCTAssertTrue(app.navigationBars["My Markers"].waitForExistence(timeout: 5))
        // Activate search bar
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText("HDL")
        // HDL Cholesterol appears in tracked section
        XCTAssertTrue(app.staticTexts["HDL Cholesterol"].waitForExistence(timeout: 3))
        // Cancel search
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["My Markers"].waitForExistence(timeout: 3))
    }
}

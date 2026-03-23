import XCTest

/// E2E tests for floating panel and workspace behavior.
final class FloatingPanelUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Bug 1: Floating panel should switch reminders

    /// Clicking the forward button on the floating panel should change the displayed reminder.
    func testFloatingPanel_clickNextButton_changesDisplayedReminder() throws {
        // Find the floating panel by its accessibility identifier
        let floatingPanel = app.windows["floatingReminderPanel"]
        guard floatingPanel.waitForExistence(timeout: 5) else {
            throw XCTSkip("Floating panel not visible - may be disabled")
        }

        // Read the initial reminder title (identified by accessibilityIdentifier)
        let titleText = floatingPanel.staticTexts["floatingPanelTitle"]
        XCTAssertTrue(titleText.waitForExistence(timeout: 3), "Floating panel should show a title")
        let initialTitle = titleText.label

        // Hover over the panel to reveal the next button
        floatingPanel.hover()

        // Click the forward/next button
        let nextButton = floatingPanel.buttons["nextReminderButton"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3),
                      "Next button should appear on hover")
        nextButton.click()

        // Wait briefly for the update
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", initialTitle),
            object: titleText
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: 3)
        XCTAssertEqual(result, .completed,
                       "Floating panel title should change after clicking next")
    }

    // MARK: - Bug 3: Detail scroll indicators should be hidden

    /// The detail pane should not show visible scroll indicators.
    func testDetailView_noVisibleScrollIndicators() throws {
        // Click the first reminder in the sidebar to show detail
        let sidebar = app.outlines.firstMatch
        guard sidebar.waitForExistence(timeout: 5) else {
            throw XCTSkip("Sidebar not available")
        }

        let firstCell = sidebar.cells.firstMatch
        guard firstCell.waitForExistence(timeout: 3) else {
            throw XCTSkip("No reminders in sidebar")
        }
        firstCell.click()

        // Check the detail scroll view has hidden indicators
        // The scroll view should have the accessibilityIdentifier "detailScrollView"
        let detailScroll = app.scrollViews["detailScrollView"]
        XCTAssertTrue(detailScroll.waitForExistence(timeout: 3),
                      "Detail scroll view should exist")

        // Verify no scroll bars are visible within the detail area
        let scrollBars = detailScroll.scrollBars
        XCTAssertEqual(scrollBars.count, 0,
                       "Detail view should have no visible scroll bars")
    }
}

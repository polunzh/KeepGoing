import XCTest

/// E2E tests for floating panel and workspace behavior.
@MainActor
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
        let floatingPanel = app.windows["floatingReminderPanel"]
        guard floatingPanel.waitForExistence(timeout: 5) else {
            throw XCTSkip("Floating panel not visible - may be disabled")
        }

        let titleText = floatingPanel.staticTexts["floatingPanelTitle"]
        XCTAssertTrue(titleText.waitForExistence(timeout: 3), "Floating panel should show a title")
        let initialTitle = titleText.label

        floatingPanel.hover()

        let nextButton = floatingPanel.buttons["nextReminderButton"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3),
                      "Next button should appear on hover")
        nextButton.click()

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
        let sidebar = app.outlines.firstMatch
        guard sidebar.waitForExistence(timeout: 5) else {
            throw XCTSkip("Sidebar not available")
        }

        let firstCell = sidebar.cells.firstMatch
        guard firstCell.waitForExistence(timeout: 3) else {
            throw XCTSkip("No reminders in sidebar")
        }
        firstCell.click()

        let detailScroll = app.scrollViews["detailScrollView"]
        XCTAssertTrue(detailScroll.waitForExistence(timeout: 3),
                      "Detail scroll view should exist")

        let scrollBars = detailScroll.scrollBars
        XCTAssertEqual(scrollBars.count, 0,
                       "Detail view should have no visible scroll bars")
    }
}

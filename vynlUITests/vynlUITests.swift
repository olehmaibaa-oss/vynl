//
//  vynlUITests.swift
//  vynlUITests
//

import XCTest

final class vynlUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Use in-memory SwiftData store so each test starts with a clean collection.
        app.launchArguments = ["-uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // Verifies the full add-release flow from empty state to list appearance.
    @MainActor
    func testAddReleaseFromEmptyState() throws {
        // Wait for the empty-state CTA to appear before tapping.
        let addButton = app.buttons["collection.addReleaseButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // Wait for the form sheet to animate in, then fill required fields.
        let artistField = app.textFields["addRelease.artistField"]
        XCTAssertTrue(artistField.waitForExistence(timeout: 3))
        artistField.tap()
        artistField.typeText("Surgeon")

        let titleField = app.textFields["addRelease.titleField"]
        titleField.tap()
        titleField.typeText("Internal Empire")

        let genreField = app.textFields["addRelease.genreField"]
        genreField.tap()
        genreField.typeText("Techno")

        // Save the release.
        app.buttons["addRelease.saveButton"].tap()

        // The new release should appear in the collection.
        XCTAssertTrue(app.staticTexts["Surgeon"].waitForExistence(timeout: 3))
    }
}

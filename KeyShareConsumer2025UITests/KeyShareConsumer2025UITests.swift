//
//  KeyShareConsumer2025UITests.swift
//  KeyShareConsumer2025UITests
//

import XCTest

final class KeyShareConsumer2025UITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testMenuOptions() throws {
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        let app = XCUIApplication()
        app.launch()
        app.buttons["Import Key"].tap()
        setupViewOptions(app)
        setupViewOptions(app, iconsOrList: .icons)
        setupViewOptions(app, iconsOrList: .icons, sort: .date)
        setupViewOptions(app, iconsOrList: .icons, sort: .date, group: .date)
        setupViewOptions(app, iconsOrList: .icons, sort: .date, group: .date, showExts: false)
    }

    // Clear the KSC key chain and make sure it worked
    @MainActor
    func testClearKeyChain() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Clear Key Chain"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)
    }

    // Import a single key from SKP root view
    @MainActor
    func testImportOneKeySuccess() throws {
        setSettings(targets: [SETTINGS[Utis.pkcs12.rawValue]])

        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        let app = XCUIApplication()
        app.launch()

        // Click the Clear Key Chain button and make sure the table is subsequently empty
        app.buttons["Clear Key Chain"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)

        // Import the first PKCS #12 file below the folders (in view shown as a List, sorted by Kind, and with no grouping)
        app.buttons["Import Key"].tap()

        // each destination has a Cancel button, so wait for it then adjust based on view type
        XCTAssertEqual(true, app.buttons["Cancel"].waitForExistence(timeout: 4))

        // move to the importRoot view or fail
        XCTAssertEqual(true, moveToRoot(app))
        setupViewOptions(app)

        app.swipeUp()

        let element = app.cells.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "encryption_38AF.p12"))
        XCTAssert(element.waitForExistence(timeout: 10))
        let isEnabled = element.isEnabled
        XCTAssert(isEnabled)
        element.tap()

        // Wait for import to occur then make sure table has one item
        XCTAssertEqual(true, app.buttons["Clear Key Chain"].waitForExistence(timeout: 4))
        XCTAssertEqual(1, app.tables.element.cells.count)

        // Click the Clear Key Chain button and make sure the table is subsequently empty
        app.buttons["Clear Key Chain"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)
    }

    // Try to import a key that is disabled by settings
    @MainActor
    func testImportOneKeyFail() throws {
        setSettings(targets: [SETTINGS[Utis.selectEnc.rawValue]])

        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        let app = XCUIApplication()
        app.launch()

        // Click the Clear Key Chain button and make sure the table is subsequently empty
        app.buttons["Clear Key Chain"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)

        // Import the first PKCS #12 file below the folders (in view shown as a List, sorted by Kind, and with no grouping)
        app.buttons["Import Key"].tap()

        // each destination has a Cancel button, so wait for it then adjust based on view type
        XCTAssertEqual(true, app.buttons["Cancel"].waitForExistence(timeout: 4))

        // move to the importRoot view or fail
        XCTAssertEqual(true, moveToRoot(app))
        setupViewOptions(app)

        app.swipeUp()

        let element = app.cells.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "encryption_38AF.p12"))
        XCTAssert(element.waitForExistence(timeout: 10))
        let isEnabled = element.isEnabled
        XCTAssert(!isEnabled)
        app.buttons["Cancel"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)
    }

    // Import a single key from SKP encryption sub-folder view
    @MainActor
    func testImportOneKeyFromFolderSuccess() throws {
        setSettings(targets: [SETTINGS[Utis.selectEnc.rawValue]])

        let app = XCUIApplication()
        app.launch()

        // Click the Clear Key Chain button and make sure the table is subsequently empty
        app.buttons["Clear Key Chain"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)

        // Import the first PKCS #12 file below the folders (in view shown as a List, sorted by Kind, and with no grouping)
        app.buttons["Import Key"].tap()

        // each destination has a Cancel button, so wait for it then adjust based on view type
        XCTAssertEqual(true, app.buttons["Cancel"].waitForExistence(timeout: 4))

        XCTAssertEqual(true, moveToRoot(app))
        setupViewOptions(app)

        let folder = app.otherElements.staticTexts["Encryption"]
        XCTAssert(folder.isEnabled)
        folder.tap()

        XCTAssertEqual(true, app.buttons.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "Actions Menu")).waitForExistence(timeout: 4))

        let element3 = app.otherElements.staticTexts["encryption_38AD.p12"]
        XCTAssertEqual(true, element3.waitForExistence(timeout: 10))
        XCTAssert(element3.isEnabled)
        element3.tap()

        // Wait for import to occur then make sure table has one item
        XCTAssertEqual(true, app.buttons["Clear Key Chain"].waitForExistence(timeout: 4))
        XCTAssertEqual(1, app.tables.element.cells.count)

        // Click the Clear Key Chain button and make sure the table is subsequently empty
        app.buttons["Clear Key Chain"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)
    }

    // Try to import a single key from SKP encryption sub-folder view, but it is not enabled
    @MainActor
    func testImportOneKeyFromFolderFail() throws {
        setSettings(targets: [SETTINGS[Utis.selectPiv.rawValue]])

        let app = XCUIApplication()
        app.launch()

        // Click the Clear Key Chain button and make sure the table is subsequently empty
        app.buttons["Clear Key Chain"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)

        // Import the first PKCS #12 file below the folders (in view shown as a List, sorted by Kind, and with no grouping)
        app.buttons["Import Key"].tap()

        // each destination has a Cancel button, so wait for it then adjust based on view type
        XCTAssertEqual(true, app.buttons["Cancel"].waitForExistence(timeout: 4))

        XCTAssertEqual(true, moveToRoot(app))
        setupViewOptions(app)

        let folder = app.otherElements.staticTexts["Encryption"]
        XCTAssert(folder.isEnabled)
        folder.tap()

        XCTAssertEqual(true, app.buttons.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "Actions Menu")).waitForExistence(timeout: 4))

        let element3 = app.cells.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "encryption_38AD.p12"))
        XCTAssertEqual(true, element3.waitForExistence(timeout: 10))
        XCTAssert(!element3.isEnabled)
        app.buttons["Cancel"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)
    }

    // Import a zip file with 12 keys from SKP root view
    @MainActor
    func testImportOneZipFileSuccess() throws {
        setSettings(targets: [SETTINGS[Utis.zipNoFilter.rawValue]])

        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        let app = XCUIApplication()
        app.launch()

        // Click the Clear Key Chain button and make sure the table is subsequently empty
        app.buttons["Clear Key Chain"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)

        // Import the first PKCS #12 file below the folders (in view shown as a List, sorted by Kind, and with no grouping)
        app.buttons["Import Key"].tap()

        // each destination has a Cancel button, so wait for it then adjust based on view type
        XCTAssertEqual(true, app.buttons["Cancel"].waitForExistence(timeout: 4))

        // move to the importRoot view or fail
        XCTAssertEqual(true, moveToRoot(app))
        setupViewOptions(app)

        app.swipeUp()
        app.swipeUp()

        let element = app.cells.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "Unfiltered.zip"))
        XCTAssert(element.waitForExistence(timeout: 10))
        let isEnabled = element.isEnabled
        XCTAssert(isEnabled)
        element.tap()

        // Wait for import to occur then make sure table has one item
        XCTAssertEqual(true, app.buttons["Clear Key Chain"].waitForExistence(timeout: 10))
        sleep(2)
        XCTAssertEqual(12, app.tables.element.cells.count)

        // Click the Clear Key Chain button and make sure the table is subsequently empty
        app.buttons["Clear Key Chain"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)
    }

    // Try to import a zip file with 12 keys from SKP root view with file disabled
    @MainActor
    func testImportOneZipFileFail() throws {
        setSettings(targets: [SETTINGS[Utis.zipEnc.rawValue]])

        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        let app = XCUIApplication()
        app.launch()

        // Click the Clear Key Chain button and make sure the table is subsequently empty
        app.buttons["Clear Key Chain"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)

        // Import the first PKCS #12 file below the folders (in view shown as a List, sorted by Kind, and with no grouping)
        app.buttons["Import Key"].tap()

        // each destination has a Cancel button, so wait for it then adjust based on view type
        XCTAssertEqual(true, app.buttons["Cancel"].waitForExistence(timeout: 4))

        // move to the importRoot view or fail
        XCTAssertEqual(true, moveToRoot(app))
        setupViewOptions(app)

        app.swipeUp()
        app.swipeUp()

        let element = app.cells.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "Unfiltered.zip"))
        XCTAssert(element.waitForExistence(timeout: 10))
        let isEnabled = element.isEnabled
        XCTAssert(!isEnabled)
        app.buttons["Cancel"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)
    }

    // Display details view
    @MainActor
    func testDisplayDetailsViewSuccess() throws {
        setSettings(targets: [SETTINGS[Utis.pkcs12.rawValue]])

        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        let app = XCUIApplication()
        app.launch()

        // Click the Clear Key Chain button and make sure the table is subsequently empty
        app.buttons["Clear Key Chain"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)

        // Import the first PKCS #12 file below the folders (in view shown as a List, sorted by Kind, and with no grouping)
        app.buttons["Import Key"].tap()

        // each destination has a Cancel button, so wait for it then adjust based on view type
        XCTAssertEqual(true, app.buttons["Cancel"].waitForExistence(timeout: 4))

        // move to the importRoot view or fail
        XCTAssertEqual(true, moveToRoot(app))
        setupViewOptions(app)

        let element = app.cells.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "encryption_38AF.p12"))
        XCTAssert(element.waitForExistence(timeout: 10))
        let isEnabled = element.isEnabled
        XCTAssert(isEnabled)
        element.press(forDuration: 2)

        app.buttons["View certificate details"].tap()
        let serial = app.staticTexts["38af"]
        XCTAssert(serial.isEnabled)
        app.buttons["Dismiss"].tap()
    }

    // Try to view certificate details for a zip file (will not be there)
    @MainActor
    func testDisplayZipDetailsViewSuccess() throws {
        setSettings(targets: [SETTINGS[Utis.zipNoFilter.rawValue]])

        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        let app = XCUIApplication()
        app.launch()

        // Click the Clear Key Chain button and make sure the table is subsequently empty
        app.buttons["Clear Key Chain"].tap()
        XCTAssertEqual(0, app.tables.element.cells.count)

        // Import the first PKCS #12 file below the folders (in view shown as a List, sorted by Kind, and with no grouping)
        app.buttons["Import Key"].tap()

        // each destination has a Cancel button, so wait for it then adjust based on view type
        XCTAssertEqual(true, app.buttons["Cancel"].waitForExistence(timeout: 4))

        // move to the importRoot view or fail
        XCTAssertEqual(true, moveToRoot(app))
        setupViewOptions(app, descending: true)

        let element = app.cells.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "Unfiltered.zip"))
        XCTAssert(element.waitForExistence(timeout: 10))
        let isEnabled = element.isEnabled
        XCTAssert(isEnabled)
        element.press(forDuration: 2)

        app.buttons["View zip details"].tap()
        sleep(1)

        let element2 = app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "encryption_38AF.p12"))
        XCTAssert(element2.waitForExistence(timeout: 10))
        let isEnabled2 = element2.isEnabled
        XCTAssert(isEnabled2)
        app.buttons["Dismiss"].tap()
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

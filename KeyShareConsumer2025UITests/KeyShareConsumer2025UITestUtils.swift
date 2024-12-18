//
//  KeyShareConsumer2025UITestUtils.swift
//  KeyShareConsumer2025UITests
//

import XCTest

// swiftformat adds trailing commas and swiftlint complains about them
// swiftlint:disable trailing_comma
let SETTINGS = [
    "All keys (purebred2025.rsa.pkcs-12)",
    "All recent keys (purebred2025.select.all)",
    "All recent user keys (purebred2025.select.all-user)",
    "Recent signature keys (purebred2025.select.signature)",
    "All encryption keys (purebred2025.select.encryption)",
    "Recent authentication keys (purebred2025.select.authentication)",
    "Recent device keys (purebred2025.select.device)",
    "All keys (purebred2025.select.no-filter)",
    "All recent keys (purebred2025.zip.all)",
    "All recent user keys (purebred2025.zip.all-user)",
    "Recent signature keys (purebred2025.zip.signature)",
    "All encryption keys (purebred2025.zip.encryption)",
    "Recent authentication keys (purebred2025.zip.authentication)",
    "Recent device keys (purebred2025.zip.device)",
    "All keys (purebred2025.zip.no-filter)",
]
// swiftlint:enable trailing_comma

public enum Utis: Int {
    case pkcs12 = 0
    case selectAll = 1
    case selectAllUser = 2
    case selectSig = 3
    case selectEnc = 4
    case selectPiv = 5
    case selectDev = 6
    case selectNoFilter = 7
    case zipAll = 8
    case zipAllUser = 9
    case zipSig = 10
    case zipEnc = 11
    case zipPiv = 12
    case zipDev = 13
    case zipNoFilter = 14
}

public enum Views {
    case mainView
    case importRoot
    case importSub
    case providerSelect
    case unknown
}

public enum IconsOrList: String {
    case icons = "Icons"
    case list = "List"
}

public enum SortCriteria: String {
    case name = "Name"
    case kind = "Kind"
    case date = "Date"
    case size = "Size"
    case tags = "Tags"
}

public enum GroupByOptions: String {
    case none = "None"
    case kind = "Kind"
    case date = "Date"
    case size = "Size"
    case sharedBy = "SharedBy"
}

func setSettings(targets: [String]) {
    let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
    settings.launch()
    settings.otherElements.staticTexts["KeyShareConsumer2025"].tap()

    for curType in SETTINGS {
        let curSwitch = settings.switches.element(matching: NSPredicate(format: "label CONTAINS[c] %@", curType))
        while !curSwitch.exists {
            settings.swipeUp()
        }
        if curSwitch.exists {
            // swiftlint:disable:next force_cast
            if curSwitch.value as! String == "0", targets.contains(curType) {
                curSwitch.switches.firstMatch.tap()
                // swiftlint:disable:next force_cast
            } else if curSwitch.value as! String == "1", !targets.contains(curType) {
                curSwitch.switches.firstMatch.tap()
            }
        }
    }
    // pause to make sure KSC is not launched before these changes are available
    sleep(2)
}

// There are four different places the app may be: KSC main view, provider root view, provider sub-folder view, select provider view.
// Detect which is displayed.
func detectView(_ app: XCUIApplication) -> Views {
    let clearKeyChain = app.buttons["Clear Key Chain"]
    if clearKeyChain.exists, clearKeyChain.isHittable {
        return Views.mainView
    }

    let subHeader = app.buttons.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "Actions Menu"))
    if subHeader.exists {
        return Views.importSub
    }

    let rootHeader = app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "SampleKeyProvider2025"))
    if rootHeader.exists {
        return Views.importRoot
    }

    let selectHeader = app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "Browse"))
    if selectHeader.exists {
        return Views.providerSelect
    }

    return Views.unknown
}

// All tests are relative to the root view of the provider, so move there.
func moveToRoot(_ app: XCUIApplication) -> Bool {
    let viewType = detectView(app)
    if Views.importRoot == viewType {
        return true
    } else if Views.importSub == viewType {
        // bizarrely, the Back button is identified by the provider name
        app.buttons["SampleKeyProvider2025"].tap()
    } else if Views.providerSelect == detectView(app) {
        app.buttons["SampleKeyProvider2025"].tap()
    }

    // Wait for importRoot view
    return app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] %@", "SampleKeyProvider2025")).waitForExistence(timeout: 4)
}

func setupViewOptions(_ app: XCUIApplication, iconsOrList: IconsOrList = .list, sort: SortCriteria = .kind, descending: Bool = false, group: GroupByOptions = .none, showExts: Bool = false) {
    // Activate "More" menu
    let moreButton = app.buttons["More"]
    XCTAssert(moreButton.waitForExistence(timeout: 10))
    moreButton.tap()

    // Select display style
    let iconsOrListButton = app.buttons[iconsOrList.rawValue]
    XCTAssert(iconsOrListButton.waitForExistence(timeout: 10))
    if !iconsOrListButton.isSelected {
        iconsOrListButton.tap()

        // Activate "More" menu again as it goes away after selecting List view
        XCTAssert(moreButton.waitForExistence(timeout: 10))
        moreButton.tap()
    }

    // If target sorting is not selected, select it then inspect for ordering.
    let sortButton = app.buttons[sort.rawValue]
    XCTAssert(sortButton.waitForExistence(timeout: 10))
    if sortButton.isSelected == false {
        sortButton.tap()

        // Activate "More" menu again as it goes away after selecting sorting
        XCTAssert(moreButton.waitForExistence(timeout: 10))
        moreButton.tap()
    } else {
        let orderTag = if descending {
            "descending"
        } else {
            "ascending"
        }

        if !sortButton.identifier.hasSuffix("\(sort.rawValue.lowercased()).\(orderTag)") {
            // click the sort button again to choose the target order
            sortButton.tap()

            // Activate "More" menu again as it goes away after selecting sorting
            XCTAssert(moreButton.waitForExistence(timeout: 10))
            moreButton.tap()
        }
    }

    let viewOptionsButton = app.buttons["View Options"]
    XCTAssert(viewOptionsButton.waitForExistence(timeout: 10))
    viewOptionsButton.tap()

    let groupButton = app.buttons[group.rawValue]
    XCTAssert(groupButton.waitForExistence(timeout: 10))
    if groupButton.isSelected == false {
        groupButton.tap()

        // Activate "More" menu again as it goes away after selecting sorting
        XCTAssert(moreButton.waitForExistence(timeout: 10))
        moreButton.tap()

        XCTAssert(viewOptionsButton.waitForExistence(timeout: 10))
        viewOptionsButton.tap()
    }

    let extsButton = app.buttons["Show All Extensions"]
    XCTAssert(extsButton.waitForExistence(timeout: 10))
    if extsButton.isSelected != showExts {
        extsButton.tap()
    } else {
        // dismiss the menu by re-clicking the view options then iconsOrList option
        XCTAssert(viewOptionsButton.waitForExistence(timeout: 10))
        viewOptionsButton.tap()
        XCTAssert(iconsOrListButton.waitForExistence(timeout: 10))
        iconsOrListButton.tap()
    }
}

//
//  KeyShareConsumer2025App.swift
//  KeyShareConsumer2025
//

import os
import SwiftUI

let logger = Logger(subsystem: "purebred.samples", category: "KeyShareConsumer")

/// Enable Strings to be thrown as Errors (poached from <https://www.hackingwithswift.com/example-code/language/how-to-throw-errors-using-strings>)
extension String: @retroactive Error {}
extension String: @retroactive LocalizedError {
    public var errorDescription: String? { self }
}

@main
struct KeyShareConsumer2App: App {
    init() {
        registerDefaultsFromSettingsBundle()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

func registerDefaultsFromSettingsBundle() {
    do {
        if var url = Bundle.main.url(forResource: "Settings", withExtension: "bundle") {
            url = url.appending(path: "Root.plist")
            let plistData = try Data(contentsOf: url)
            if let defaults = try PropertyListSerialization.propertyList(from: Data(plistData), options: .mutableContainers, format: nil) as? [String: AnyObject] {
                UserDefaults.standard.register(defaults: defaults)
            } else {
                logger.error("Failed to parse data as Plist in registerDefaultsFromSettingsBundle")
            }
        }
    } catch {
        logger.error("Failed to register settings: \(error)")
    }
}

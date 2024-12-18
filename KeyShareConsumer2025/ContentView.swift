//
//  ContentView.swift
//  KeyShareConsumer2025
//

import SwiftUI
import UniformTypeIdentifiers

/// Displays the UI, which consists of two buttons and a table view. Implements the ``TableViewDelegate`` protocol in support of two
/// different instantiations of ``TableView``. The first instantiation displays key chain contents and the second displays attributes associated
/// with a key selected in the first instantiation.
struct ContentView: View {
    /// Nested class to serve as a delegate for the ``TableView`` instances used to display key chain contents or attributes of a selected key.
    class Delegate: TableViewDelegate, ObservableObject {
        /// When true the ``TableView`` shows attributes of the key selected by the user. When false, key chain contents are shown.
        @Published var keyAttrsViewActive = false

        /// Zero-based index of the selected key in the ``TableView`` displaying key chain contents. Set in ``onTapped`` when ``keyAttrsViewActive`` is false.
        @Published var selectedKeyRow = 0

        // MARK: - TableViewDelegate Functions

        func onScroll(_: TableView, isScrolling _: Bool) {
            // nothing to do
        }

        func onAppear(_: TableView, at _: Int) {
            // nothing to do
        }

        func onTapped(_: TableView, at index: Int) {
            if !self.keyAttrsViewActive {
                self.selectedKeyRow = index
                self.keyAttrsViewActive.toggle()
                self.keyAttrsViewActive = true
            }
        }

        func heightForRow(_: TableView, at _: Int) -> CGFloat {
            64.0
        }
    }

    /// Instance of nested ``Delegate`` class
    @StateObject var delegate: Delegate = .init()

    /// Key chain contents accessed using the default `KeyChainDataSourceMode.ksmIdentities` mode
    @StateObject var kcds = KeyChainDataSource()

    /// Set to true when Import Key button is clicked.
    @State private var isShowingPicker = false

    /// Contains list of UTIs configued in the Settings app. When empty, a default value of ["com.rsa.pkcs12"] is used.
    @State private var utis: [UTType]

    /// Read settings configured in the Settings app
    init() {
        utis = readSettingsAsUTType()
    }

    /// Body consisting of two buttons and a ``TableView``. Rows in the ``TableView`` can be clicked to display a different ``TableView`` instance
    /// showing detail inforrmation about the selected key.
    var body: some View {
        NavigationStack {
            // The "buttonStyle(BorderlessButtonStyle())" bit was poached from:
            // https://www.hackingwithswift.com/forums/swiftui/buttons-in-a-form-section/6175.
            // This trick avoids having both buttons in the HStack clicked when either is clicked.
            HStack {
                Button("Import Key", action: importKey)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .buttonStyle(BorderlessButtonStyle()).padding()
                Button("Clear Key Chain", action: clearKeyChain).frame(maxWidth: .infinity, alignment: .trailing).buttonStyle(BorderlessButtonStyle()).padding()
            }
            // Create an instance of TableView that lists key chain contents. Each row is clickable and when clicked displays
            // a TableView instance that shows the attributes associated with the corresponding key. The dataSource for the
            // first TableView is dynamic and will update the table when loadKeyChainContents is called. The dataSource for
            // the second TableView is static.
            TableView(dataSource: self.kcds, delegate: self.delegate).navigationDestination(isPresented: self.$delegate.keyAttrsViewActive) {
                TableView(dataSource: self.kcds.getAttributesForRow(row: self.delegate.selectedKeyRow), delegate: self.delegate, clickableRows: false)
            }
        }.scrollContentBackground(.hidden).sheet(isPresented: $isShowingPicker) {
            DocumentPicker(self.utis, update: {
                // reload the key chain contents, which should trigger table view to redraw
                kcds.loadKeyChainContents(utisToLoad: [])
            })
        }.onAppear {
            // load key chain contents on start-up (needs to be here instead of init owing to being marked as a StateObject
            kcds.loadKeyChainContents(utisToLoad: [])
        }
    }

    // MARK: - Button click handlers

    private func importKey() {
        self.utis = readSettingsAsUTType()
        isShowingPicker = true
    }

    private func clearKeyChain() {
        deleteAllItemsForSecClass(kSecClassGenericPassword)
        deleteAllItemsForSecClass(kSecClassInternetPassword)
        deleteAllItemsForSecClass(kSecClassCertificate)
        deleteAllItemsForSecClass(kSecClassKey)
        deleteAllItemsForSecClass(kSecClassIdentity)
        kcds.loadKeyChainContents(utisToLoad: [])
    }
}

#Preview {
    ContentView()
}

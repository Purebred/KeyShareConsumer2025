//
//  DocumentPicker.swift
//  KeyShareConsumer2025
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import ZIPFoundation

/// The ``DocumentPicker`` struct is a bridge between SwiftUI and UIKit, where the KeyShareConsumer2025 app uses
/// SwiftUI and the ``UIDocumentPickerViewController`` uses UIKit. This is based on the sample provided in this tutorial:
/// <https://www.hackingwithswift.com/books/ios-swiftui/wrapping-a-uiviewcontroller-in-a-swiftui-view>.
struct DocumentPicker: UIViewControllerRepresentable {
    /// List of Uniform Type Identifiers the document picker should enable a user to choose
    private var utis: [UTType]
    /// Callback used to tell the caller to update any UI components that vary with key chain contents
    private var update: () -> Void

    /// Initialize an instance with a list of UTIs the document picker should enable a user to choose and a callback
    /// function that updates the data source used by the table view.
    init(_ utis: [UTType], update: @escaping () -> Void) {
        self.utis = utis
        self.update = update
    }

    // MARK: - UIViewControllerRepresentable methods

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: utis)
        docPicker.delegate = context.coordinator
        return docPicker
    }

    func updateUIViewController(_: UIDocumentPickerViewController, context _: Context) {}

    // MARK: - Coordinator and Coordinator-related methods

    func makeCoordinator() -> Coordinator {
        Coordinator(update: update)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var update: () -> Void
        init(update: @escaping () -> Void) {
            self.update = update
        }

        // swiftlint:disable function_body_length
        /// Takes a reference to a service and a URL and attempts to process the URL as a PKCS #12 file (or zip file containing PKCS #12
        /// files) using a password retrieved via the service to decrypt the file. The service may or may not implement the required
        /// KeySharingPassword interface. If not, an error is logged.
        private func processPkcs12Files(service: NSFileProviderService, url: URL) {
            service.getFileProviderConnection(completionHandler: { connection, error in
                if error != nil {
                    logger.error("\(error)")
                    return
                } else if let connection {
                    connection.remoteObjectInterface = NSXPCInterface(with: KeySharingPassword.self)
                    connection.resume()

                    let helperProxy = connection.remoteObjectProxyWithErrorHandler { error in
                        logger.error("Error configuring remote object proxy: \(error)")
                    } as? KeySharingPassword

                    if let helperProxy {
                        helperProxy.fetchPassword { password, error in
                            if error != nil {
                                logger.error("Failed to fetch password via KeySharingPassword protocol with error: \(error)")
                            } else if let password {
                                let fileCoordinator = NSFileCoordinator()
                                fileCoordinator.coordinate(readingItemAt: url, options: NSFileCoordinator.ReadingOptions.withoutChanges, error: nil, byAccessor: { readURL in
                                    do {
                                        let fileData = try Data(contentsOf: readURL)
                                        if !readURL.absoluteString.hasSuffix(".zip") {
                                            let status = importP12(pkcs12Data: fileData, password: password)
                                            if status != errSecSuccess, status != errSecDuplicateItem {
                                                logger.error("Failed to import PKCS #12 item with \(status)")
                                            }
                                        } else {
                                            let archive = try Archive(url: readURL, accessMode: .read)
                                            for entry in archive {
                                                _ = try archive.extract(entry, consumer: { data in
                                                    let status = importP12(pkcs12Data: data, password: password)
                                                    if status != errSecSuccess, status != errSecDuplicateItem {
                                                        logger.error("Failed to import PKCS #12 item from zip file with \(status)")
                                                    }
                                                })
                                            }
                                        }
                                    } catch {
                                        logger.error("Failed to read PKCS #12 data from \(readURL): \(error)")
                                    }
                                    // tell the view to reload
                                    self.update()
                                })
                            } else {
                                logger.error("Failed to fetch password via KeySharingPassword protocol but no error was returned")
                            }
                        }
                    } else {
                        logger.error("Proxy object does not support the KeySharingPassword protocol")
                    }
                } else {
                    logger.error("getFileProviderConnection did not return an error or connection")
                }
            })
        }

        // swiftlint:enable function_body_length

        // MARK: - UIDocumentPickerDelegate methods

        func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            logger.debug("documentPicker: \(urls)")
            if urls.isEmpty {
                logger.error("documentPicker received an empty array of URLs")
                return
            }

            let url = urls[0]
            guard url.startAccessingSecurityScopedResource() else {
                logger.error("startAccessingSecurityScopedResource failed")
                return
            }

            FileManager.default.getFileProviderServicesForItem(at: url, completionHandler: { services, error in
                if error != nil {
                    logger.error("Failed to retrieve list of services for URL: \(error)")
                } else if let services {
                    let keys = services.keys
                    logger.debug("Services: \(keys)")
                    for key in keys {
                        if let service = services[key] {
                            self.processPkcs12Files(service: service, url: url)
                            return
                        }
                    }
                    url.stopAccessingSecurityScopedResource()
                } else {
                    logger.error("Failed to retrieve list of services for URL")
                }
            })
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            logger.debug("documentPickerWasCancelled")
            controller.dismiss(animated: true, completion: nil)
        }
    }
}

# Key Share Consumer 2025

[Purebred](https://public.cyber.mil/pki-pke/purebred-2/) is the derived credential issuing system for the United States (U.S.) Department of Defense (DoD). Since 2016, the Purebred app for iOS has featured a custom "key sharing" interface that allows PKCS #12 objects and the corresponding passwords to be shared from the Purebred app to unrelated apps via the iOS file provider extension APIs and the system pasteboard. Two sample apps were prepared as a demonstration and to enable application developers to test integration with the key sharing interface and to demonstrate usage: [SampleKeyProvider](https://github.com/Purebred/SampleKeyProvider) and [KeyShareConsumer](https://github.com/Purebred/KeyShareConsumer). 

Since 2020, the Purebred app for iOS has featured a [persistent token](https://developer.apple.com/documentation/cryptotokenkit) extension that enables unrelated apps to use keys provisioned via Purebred without exporting and sharing the private keys. The persistent token interface is the preferred way to exercise Purebred-provisioned keys on iOS devices. As with key sharing, two sample apps were prepared to enable application developers to test integration with the persistent token interface and to demonstrate usage: [CtkProvider](https://github.com/Purebred/CtkProvider) and [CtkConsumer](https://github.com/Purebred/CtkConsumer).

In the years since 2016, several APIs that underpin the key sharing mechanism have been deprecated. To avoid use of deprecated APIs, the key sharing mechanism has been updated. Unfortunately, these changes are not cross-compatible and result in changes to the user experience. Two new sample apps, SampleKeyProvider2025 and KeyShareConsumer2025, are now available to facilitate testing and usage of the updated key sharing interface.

## Primary differences between legacy key sharing and key sharing 2025

### UIDocumentPickerViewController usage

In legacy key sharing, the process is initiated by launching an instance of [UIDocumentPickerViewController](https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller?language=objc) that was initialized using the deprecated method shown below.

```objectivec
UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:utis inMode:UIDocumentPickerModeOpen];
documentPicker.delegate = self;
documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
[self presentViewController:documentPicker animated:YES completion:nil];
```

In key sharing 2025, a different initializer is used.

```objectivec
UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes: uniformTypeIdentifiers];
documentPicker.delegate = self;
documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
[self presentViewController:documentPicker animated:YES completion:nil];
```

In legacy key sharing, the list of uniform type identifiers (UTIs) is passed as an array of string. In key sharing 2025, the list is passed as an array of ``UTType``.

### Password retrieval

In legacy key sharing, the password required to decrypt a PKCS #12 file is retrieved from the system pasteboard. In key sharing 2025, the system pasteboard does not play a role in the process. Instead, the providing app implements an instance of [NSFileProviderServiceSource](https://developer.apple.com/documentation/fileprovider/nsfileproviderservicesource?language=objc) that implements the custom ``KeySharingPassword`` protocol, which is defined as shown below.

```swift
typealias PasswordHandler = (_ password: String?, _ error: NSError?) -> Void

let keySharingPasswordv1 = NSFileProviderServiceName("red.hound.KeySharingPassword-v1.0.0")

@objc protocol KeySharingPassword {
    func fetchPassword(_ completionHandler: PasswordHandler?)
}
```

A brief example of exercising the protocol (with no error handling) is shown below. The Key Share Consumer 2025 app includes a more complete example, written in Swift. The key_sharing_2025 branch of the original Key Share Consumer app includes a more complete example written in Objective-C.

```objectivec
NSURL* url = urls[0];
BOOL startAccessingWorked = [url startAccessingSecurityScopedResource];

[[NSFileManager defaultManager] getFileProviderServicesForItemAtURL:url completionHandler:^(NSDictionary<NSFileProviderServiceName,NSFileProviderService *> * _Nullable services, NSError * _Nullable error) {
    NSArray* keys = [services allKeys];
    for(NSString* key in keys) {
        NSFileProviderService* obj = [services objectForKey:key];
        [obj getFileProviderConnectionWithCompletionHandler:^(NSXPCConnection * _Nullable connection, NSError * _Nullable error)  {
            connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol: @protocol(KeySharingPassword)];
            [connection resume];
            
            id<KeySharingPassword> helperProxy = [connection remoteObjectProxyWithErrorHandler:^(NSError* error) {}];
            
            [helperProxy fetchPassword:^(NSString * _Nullable password, NSError * _Nullable error) {
                NSLog(@"%@", password);
                [url stopAccessingSecurityScopedResource];
            }];
        }];
    }
}];
```

### Uniform type identifiers (UTIs)

Legacy key sharing and key sharing 2025 use different UTIs. This prevents inadvertent attempts to import keys from an incompatible implementation. The table below shows the UTIs from each implementation.

|Legacy UTI|2025 UTI|
|---------|:-----------:|
|com.rsa.pkcs-12|purebred2025.rsa.pkcs-12|
|purebred.select.all|purebred2025.select.all|
|purebred.select.all-user|purebred2025.select.all-user|
|purebred.select.device|purebred2025.select.device|
|purebred.select.signature|purebred2025.select.signature|
|purebred.select.encryption|purebred2025.select.encryption|
|purebred.select.authentication|purebred2025.select.authentication|
|purebred.select.no-filter|purebred2025.select.no-filter|
|purebred.zip.all|purebred2025.zip.all|
|purebred.zip.all-user|purebred2025.zip.all-user|
|purebred.zip.device|purebred2025.zip.device|
|purebred.zip.signature|purebred2025.zip.signature|
|purebred.zip.encryption|purebred2025.zip.encryption|
|purebred.zip.authentication|purebred2025.zip.authentication|
|purebred.zip.no-filter|purebred2025.zip.no-filter|
|||

Though the UTIs feature similar names, there are some significant differences in terms of functionality. In legacy key sharing, the ``purebred.select.*`` UTIs cause display of the most recent PKCS #12 file(s) of the given certificate type. In key sharing 2025, the ``purebred2025.select.*`` UTIs cause display of folders containing the most recent PKCS #12 file(s) of the given certificate type. To enable display the contents of a folder, a companion UTI must also be asserted. The following table lists the UTIs that correspond to the ``purebred.select.*`` UTIs and enable display of PKCS #12 files.

|2025 UTI|Purpose|
|---------|:-----------:|
|purebred2025.select.all-p12|Display contents of purebred2025.select.all folders|
|purebred2025.select.all-user-p12|Display contents of purebred2025.select.all-user folders|
|purebred2025.select.device-p12|Display contents of purebred2025.select.device folders|
|purebred2025.select.signature-p12|Display contents of purebred2025.select.signature folders|
|purebred2025.select.encryption-p12|Display contents of purebred2025.select.encryption folders|
|purebred2025.select.authentication-p12|Display contents of purebred2025.select.authentication folders|
|purebred2025.select.no-filter-p12|Display contents of purebred2025.select.no-filter folders|

In legacy key sharing, the ``*.no-filter`` UTIs are combined with other UTIs to cause display of all PKCS #12 files of the given certificate type. In key sharing 2025, the ``.no-filter`` UTIs cause display of a folder or a zip file containing all available PKCS #12 files of all types.

The original UTIs that features an '_' character have been deprecated for several years and must not be used.

### Regression tests

At present, the regression tests assume Sample Key Provider 2025 has been installed, provisioned and used at least once to import a key into Key Share Consumer 2025. The tests do not currently work on a fresh device or with a Key Share Consumer 2025 instance that has not previously imported a key.

### Documentation

Documentation can be generated using XCode via the `Product->Build Documentation` menu item. Alternatively, the following steps can be performed to build documentation from source.

```bash
mkdir ~/Desktop/kscdocs
xcodebuild docbuild -scheme KeyShareConsumer2025 -workspace KeyShareConsumer2025.xcworkspace  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath ~/Desktop/kscdocs/
```

The resulting `KeyShareConsumer2025.doccarchive` can be subsequently found in the `~/Desktop/kscdocs/Build/Products/Debug-iphonesimulator` folder.

### Building

Prior to attempting to build the project, replace the project's bundle identifier.
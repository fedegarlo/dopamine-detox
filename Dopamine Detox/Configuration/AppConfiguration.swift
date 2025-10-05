import Foundation

enum AppConfiguration {
    static let minimumSupportedIOSVersion = OperatingSystemVersion(majorVersion: 17, minorVersion: 0, patchVersion: 0)
    
    static var isDeviceSupportedForFocus: Bool {
        ProcessInfo.processInfo.isOperatingSystemAtLeast(minimumSupportedIOSVersion)
    }
}
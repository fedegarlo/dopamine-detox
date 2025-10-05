import Foundation
import Combine
import os.log
import UIKit
#if canImport(FocusConfiguration)
import FocusConfiguration
#endif
#if canImport(FocusConfigurationUI)
import FocusConfigurationUI
#endif

@MainActor
final class FocusAutomationManager: ObservableObject {
    
    static let shared = FocusAutomationManager()

    enum Status: Equatable {
        case unsupported
        case needsAuthorization
        case denied
        case needsConfiguration
        case ready(name: String)
    }

    @Published private(set) var status: Status = .unsupported
    @Published private(set) var isActivatingFocus = false
    @Published private(set) var isDeactivatingFocus = false

    private let logger = Logger(subsystem: "com.dopamine.detox", category: "FocusAutomation")
    private let userDefaults: UserDefaults
    private let identifierKey = "focusAutomation.selectedConfigurationIdentifier"
    private let nameKey = "focusAutomation.selectedConfigurationName"

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        refreshStatus()
    }

    func refreshStatus() {
#if canImport(FocusConfiguration)
        guard #available(iOS 17, *) else {
            logger.info("refreshStatus: iOS below 17; FocusConfiguration requires iOS 17+; marking unsupported")
            status = .unsupported
            return
        }

        let authStatus = FocusConfigurationManager.shared.authorizationStatus
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let authStatusDescription = String(describing: authStatus)
        let storedIdString = (storedConfigurationIdentifier != nil) ? "yes" : "no"
        let storedNameString = storedConfigurationName ?? "nil"
        logger.info("refreshStatus: iOS \(osVersion, privacy: .public); FocusConfiguration authStatus = \(authStatusDescription, privacy: .public); storedID=\(storedIdString, privacy: .public); storedName=\(storedNameString, privacy: .public)")
        switch authStatus {
        case .notDetermined:
            status = .needsAuthorization
        case .restricted, .denied:
            status = .denied
        case .authorized:
            if storedConfigurationIdentifier != nil, let name = storedConfigurationName {
                status = .ready(name: name)
            } else {
                status = .needsConfiguration
            }
        @unknown default:
            // Fallback for future iOS versions introducing new authorization states.
            // Do not mark as unsupported; prefer a conservative, user-friendly state.
            if let name = storedConfigurationName {
                status = .ready(name: name)
            } else if storedConfigurationIdentifier != nil {
                status = .ready(name: "Focus")
            } else {
                // If we don't have a stored configuration yet, prompt the user to authorize/configure.
                status = .needsAuthorization
            }
            logger.warning("Unknown Focus authorizationStatus encountered; applying fallback")
        }
        logger.info("refreshStatus: mapped app status = \(String(describing: status), privacy: .public)")
#else
        logger.info("refreshStatus: FocusConfiguration not available at compile time (canImport failed); marking unsupported")
        status = .unsupported
#endif
    }

    func requestAuthorizationIfNeeded() async {
#if canImport(FocusConfiguration)
        guard #available(iOS 17, *), status == .needsAuthorization else { return }

        do {
            try await FocusConfigurationManager.shared.requestAuthorization()
        } catch {
            logger.error("Focus authorization request failed: \(error.localizedDescription, privacy: .public)")
        }

        refreshStatus()
#endif
    }

    func presentConfigurationPicker(from scene: UIWindowScene?) async {
#if canImport(FocusConfigurationUI) && canImport(FocusConfiguration)
        guard #available(iOS 17, *), status != .unsupported else { return }
        guard let scene else {
            logger.error("Missing UIWindowScene when presenting FocusConfigurationPicker")
            return
        }

        do {
            let picker = FocusConfigurationPicker(configurationKinds: [.filter])
            let result = try await picker.present(from: scene)

            switch result {
            case .selection(let configuration):
                storedConfigurationIdentifier = configuration.identifier
                storedConfigurationName = configuration.localizedName
                logger.info("Stored focus configuration \(configuration.localizedName, privacy: .public)")
            case .none:
                break
            @unknown default:
                break
            }
        } catch {
            logger.error("Failed to present FocusConfigurationPicker: \(error.localizedDescription, privacy: .public)")
        }

        refreshStatus()
#else
        openSettings()
#endif
    }

    func beginDetoxSession() {
#if canImport(FocusConfiguration)
        guard #available(iOS 17, *), case .ready = status else { return }
        guard let identifier = storedConfigurationIdentifier else { return }

        Task {
            await activateFocusConfiguration(with: identifier)
        }
#endif
    }

    func endDetoxSession() {
#if canImport(FocusConfiguration)
        guard #available(iOS 17, *), let identifier = storedConfigurationIdentifier else { return }

        Task {
            await deactivateFocusConfiguration(with: identifier)
        }
#endif
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var storedConfigurationIdentifier: UUID? {
        get {
            guard let value = userDefaults.string(forKey: identifierKey) else { return nil }
            return UUID(uuidString: value)
        }
        set {
            if let newValue {
                userDefaults.set(newValue.uuidString, forKey: identifierKey)
            } else {
                userDefaults.removeObject(forKey: identifierKey)
            }
        }
    }

    private var storedConfigurationName: String? {
        get { userDefaults.string(forKey: nameKey) }
        set {
            if let newValue {
                userDefaults.set(newValue, forKey: nameKey)
            } else {
                userDefaults.removeObject(forKey: nameKey)
            }
        }
    }

#if canImport(FocusConfiguration)
    @available(iOS 17, *)
    private func activateFocusConfiguration(with identifier: UUID) async {
        guard !isActivatingFocus else { return }
        isActivatingFocus = true
        defer { isActivatingFocus = false }

        do {
            try await FocusConfigurationManager.shared.activateFocusConfiguration(withIdentifier: identifier)
            logger.info("Activated focus configuration during detox session")
        } catch {
            logger.error("Failed to activate focus configuration: \(error.localizedDescription, privacy: .public)")
        }
    }

    @available(iOS 17, *)
    private func deactivateFocusConfiguration(with identifier: UUID) async {
        guard !isDeactivatingFocus else { return }
        isDeactivatingFocus = true
        defer { isDeactivatingFocus = false }

        do {
            try await FocusConfigurationManager.shared.deactivateFocusConfiguration(withIdentifier: identifier)
            logger.info("Deactivated focus configuration after detox session")
        } catch {
            logger.error("Failed to deactivate focus configuration: \(error.localizedDescription, privacy: .public)")
        }
    }
#endif
}


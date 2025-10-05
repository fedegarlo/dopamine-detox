import SwiftUI

struct FocusAutomationCard: View {
    @ObservedObject var focusManager: FocusAutomationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(title)
                    .font(.headline)
            } icon: {
                Image(systemName: iconName)
                    .foregroundStyle(.secondary)
            }

            Text(description)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let actionTitle = actionTitle {
                if #available(iOS 15.0, *) {
                    Button(actionTitle) {
                        Task { await performPrimaryAction() }
                    }
                    .controlSize(.small)
                } else {
                    Button(actionTitle) {
                        Task { await performPrimaryAction() }
                    }
                    .buttonStyle(DefaultButtonStyle())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var title: String {
        switch focusManager.status {
        case .unsupported:
            return "Focus Filters not available"
        case .needsAuthorization:
            return "Authorize Focus Filters"
        case .denied:
            return "Focus Filters denied"
        case .needsConfiguration:
            return "Choose a Focus to silence notifications"
        case .ready(let name):
            return "\(name) will auto-activate"
        }
    }

    private var description: String {
        switch focusManager.status {
        case .unsupported:
            return "Update to the latest iOS version to silence notifications automatically during detox sessions."
        case .needsAuthorization:
            return "Allow Dopamine Detox to control Focus Filters so we can mute notifications when a session begins."
        case .denied:
            return "You previously denied Focus Filters access. Enable it in Settings to silence notifications automatically."
        case .needsConfiguration:
            return "Pick which Focus mode the app should enable each time you start a detox."
        case .ready(let name):
            return "We'll enable \(name) as soon as your detox starts and disable it when you finish."
        }
    }

    private var iconName: String {
        switch focusManager.status {
        case .ready:
            return "moon.zzz.fill"
        case .unsupported, .needsAuthorization, .needsConfiguration, .denied:
            return "moon.zzz"
        }
    }

    private var actionTitle: String? {
        switch focusManager.status {
        case .unsupported:
            return nil
        case .needsAuthorization:
            return "Enable Focus Filters"
        case .denied:
            return "Open Settings"
        case .needsConfiguration:
            return "Choose Focus"
        case .ready:
            return "Change Focus"
        }
    }

    private var useProminentButton: Bool {
        switch focusManager.status {
        case .ready:
            return false
        case .unsupported, .needsAuthorization, .needsConfiguration, .denied:
            return true
        }
    }

    private func performPrimaryAction() async {
        switch focusManager.status {
        case .unsupported:
            break
        case .needsAuthorization:
            await focusManager.requestAuthorizationIfNeeded()
        case .needsConfiguration, .ready:
            await focusManager.presentConfigurationPicker(from: activeWindowScene())
        case .denied:
            focusManager.openSettings()
        }
    }

    private func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
}

import Combine
import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var isEnabled: Bool = false
    @Published private(set) var statusDescription: String = ""

    init() {
        refresh()
    }

    func refresh() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled
        statusDescription = Self.description(for: status)
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }

        refresh()
    }

    private static func description(for status: SMAppService.Status) -> String {
        switch status {
        case .enabled:
            return "Wallmove will start automatically after login."
        case .notRegistered:
            return "Wallmove will only launch when you open it manually."
        case .requiresApproval:
            return "macOS requires approval in System Settings to finish enabling launch at login."
        case .notFound:
            return "Launch at login is unavailable until the app is built and signed by Xcode."
        @unknown default:
            return "Launch at login status is currently unknown."
        }
    }
}

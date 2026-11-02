import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
public final class LaunchAtLoginManager {
    public static let shared = LaunchAtLoginManager()

    public static let userDefaultsKey = "launchAtLogin"

    public var isEnabled: Bool {
        didSet {
            guard oldValue != isEnabled else { return }
            UserDefaults.standard.set(isEnabled, forKey: Self.userDefaultsKey)
            apply(isEnabled)
        }
    }

    private init() {
        if let explicit = UserDefaults.standard.object(forKey: Self.userDefaultsKey) as? Bool {
            self.isEnabled = explicit
        } else {
            // Check status of modern SMAppService if registered
            if SMAppService.mainApp.status == .enabled {
                self.isEnabled = true
            } else if SMAppService.mainApp.status == .requiresApproval {
                self.isEnabled = false
            } else {
                self.isEnabled = true
            }
        }
    }

    public func configureOnLaunch() {
        UserDefaults.standard.register(defaults: [Self.userDefaultsKey: true])
        if SMAppService.mainApp.status == .requiresApproval {
            if isEnabled {
                isEnabled = false
            }
            return
        }
        apply(isEnabled)
    }

    private func apply(_ enable: Bool) {
        guard !Store.isOverridden else { return }
        do {
            if enable {
                if SMAppService.mainApp.status == .enabled {
                    try? SMAppService.mainApp.unregister()
                }
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently handled in CLI/testing environment where SMAppService bundle registration is unavailable
        }
    }
}

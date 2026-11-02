import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
public final class LaunchAtLoginManager {
    public static let shared = LaunchAtLoginManager()

    public static let userDefaultsKey = "launchAtLogin"

    public var isEnabled: Bool {
        get {
            // Check status of modern SMAppService if registered
            if SMAppService.mainApp.status == .enabled {
                return true
            }
            if SMAppService.mainApp.status == .requiresApproval {
                return false
            }
            // Use explicit user preference if stored, otherwise default is true
            if let explicit = UserDefaults.standard.object(forKey: Self.userDefaultsKey) as? Bool {
                return explicit
            }
            return true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.userDefaultsKey)
            apply(newValue)
        }
    }

    private init() {}

    public func configureOnLaunch() {
        UserDefaults.standard.register(defaults: [Self.userDefaultsKey: true])
        if isEnabled && SMAppService.mainApp.status != .enabled {
            apply(true)
        }
    }

    private func apply(_ enable: Bool) {
        do {
            if enable {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            // Silently handled in CLI/testing environment where SMAppService bundle registration is unavailable
        }
    }
}

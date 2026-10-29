import SwiftUI

/// The Settings window (Command-Comma). One tab per topic, at most about
/// six. Each tab is a grouped Form that sizes to its content, so the
/// window grows to fit and shows no scroll bar it does not need.
struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.settingsTab) {
            ForEach(SettingsTab.allCases) { tab in
                page(tab)
                    .tabItem { Label(tab.title, systemImage: tab.symbol) }
                    .tag(tab)
            }
        }
        .noInitialFocus()
        .bringWindowToFrontOnOpen()
    }

    @ViewBuilder
    private func page(_ tab: SettingsTab) -> some View {
        Form {
            switch tab {
            case .general: GeneralSettings()
            case .appearance: AppearanceSettings()
            }
        }
        .formStyle(.grouped)
        .fitsContent()
        .frame(width: 520)
    }
}

/// The Settings tabs. Snapshot mode walks through every case.
enum SettingsTab: String, CaseIterable, Identifiable {
    case general, appearance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .appearance: "Appearance"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintpalette"
        }
    }
}

struct GeneralSettings: View {
    @AppStorage("historyLimit") private var historyLimit = 100
    @AppStorage("confirmDelete") private var confirmDelete = true

    var body: some View {
        Section("History") {
            Picker("History limit", selection: $historyLimit) {
                Text("25 items").tag(25)
                Text("50 items").tag(50)
                Text("100 items (default)").tag(100)
                Text("200 items").tag(200)
                Text("500 items").tag(500)
                Text("1000 items").tag(1000)
            }
            .onChange(of: historyLimit) { _, _ in
                ClipboardHistory.shared.enforceLimit()
            }
        }

        Section("Items") {
            Toggle("Ask before deleting items", isOn: $confirmDelete)
        }
    }
}

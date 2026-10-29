import SwiftUI
import ClipsKit

/// The Settings window (Command-Comma). One tab per topic, at most about
/// six. Each tab is a grouped Form that sizes to its content, so the
/// window grows to fit and shows no scroll bar it does not need.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("appLanguage") private var appLanguage: String = "system"

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
        case .general: L10n.tr(.generalTab)
        case .appearance: L10n.tr(.appearanceTab)
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
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    @AppStorage("historyLimit") private var historyLimit = 100
    @AppStorage("confirmDelete") private var confirmDelete = true

    var body: some View {
        Section(L10n.tr(.language)) {
            Picker(L10n.tr(.language), selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang.rawValue)
                }
            }
        }

        Section(L10n.tr(.history)) {
            Picker(L10n.tr(.historyLimit), selection: $historyLimit) {
                Text(L10n.tr(.itemsCount(25))).tag(25)
                Text(L10n.tr(.itemsCount(50))).tag(50)
                Text(L10n.tr(.defaultOption(100))).tag(100)
                Text(L10n.tr(.itemsCount(200))).tag(200)
                Text(L10n.tr(.itemsCount(500))).tag(500)
                Text(L10n.tr(.itemsCount(1000))).tag(1000)
            }
            .onChange(of: historyLimit) { _, _ in
                ClipboardHistory.shared.enforceLimit()
            }
            Text(L10n.tr(.historyLimitDescription))
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section(L10n.tr(.items)) {
            Toggle(L10n.tr(.askBeforeDeleting), isOn: $confirmDelete)
        }
    }
}

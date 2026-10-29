import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case en = "en"
    case ptBR = "pt-BR"
    case ptPT = "pt-PT"
    case es = "es"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system:
            return "System Default"
        case .en:
            return "English"
        case .ptBR:
            return "Português (Brasil)"
        case .ptPT:
            return "Português (Portugal)"
        case .es:
            return "Español"
        }
    }
}

public enum L10n {
    public static var selectedLanguage: AppLanguage {
        get {
            let val = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
            return AppLanguage(rawValue: val) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "appLanguage")
        }
    }

    public static var current: AppLanguage {
        let selected = selectedLanguage
        if selected != .system {
            return selected
        }
        for pref in Locale.preferredLanguages {
            let lower = pref.lowercased()
            if lower.hasPrefix("pt-pt") || lower == "pt_pt" {
                return .ptPT
            } else if lower.hasPrefix("pt") {
                return .ptBR
            } else if lower.hasPrefix("es") {
                return .es
            } else if lower.hasPrefix("en") {
                return .en
            }
        }
        return .en
    }

    public static func tr(_ key: Key, lang: AppLanguage = current) -> String {
        switch lang {
        case .system:
            return tr(key, lang: current)
        case .en:
            return key.en
        case .ptBR:
            return key.ptBR
        case .ptPT:
            return key.ptPT
        case .es:
            return key.es
        }
    }

    public enum Key {
        case all
        case favorites
        case searchPlaceholder
        case noClipsFound
        case noFavoritesYet
        case starHint
        case copyHint
        case quickPaste
        case paste
        case close
        case deleteClip
        case enableAutoPaste
        case accessibilityHelp
        case openClips
        case allClipsMenu
        case favoritesMenu
        case clearNonFavorites
        case settings
        case quit
        case generalTab
        case appearanceTab
        case language
        case history
        case historyLimit
        case historyLimitDescription
        case items
        case askBeforeDeleting
        case accentColor
        case itemsCount(Int)
        case defaultOption(Int)

        var en: String {
            switch self {
            case .all: return "All"
            case .favorites: return "Favorites"
            case .searchPlaceholder: return "Search clips or apps..."
            case .noClipsFound: return "No clips found"
            case .noFavoritesYet: return "No favorite clips yet"
            case .starHint: return "Star any clip to keep it handy here."
            case .copyHint: return "Copy text, URLs, or images and they will appear here."
            case .quickPaste: return "Quick paste"
            case .paste: return "Paste"
            case .close: return "Close"
            case .deleteClip: return "Delete clip"
            case .enableAutoPaste: return "Enable Auto-Paste"
            case .accessibilityHelp: return "Accessibility permission required to auto-paste into active apps"
            case .openClips: return "Open Clips (⌘⇧V)"
            case .allClipsMenu: return "All Clips (⌘<)"
            case .favoritesMenu: return "Favorites (⌘1)"
            case .clearNonFavorites: return "Clear Non-Favorites"
            case .settings: return "Settings..."
            case .quit: return "Quit Clips"
            case .generalTab: return "General"
            case .appearanceTab: return "Appearance"
            case .language: return "Language"
            case .history: return "History"
            case .historyLimit: return "History limit"
            case .historyLimitDescription: return "Older non-favorite clips will be automatically removed once this limit is reached."
            case .items: return "Items"
            case .askBeforeDeleting: return "Ask before deleting items"
            case .accentColor: return "Accent color"
            case .itemsCount(let n): return "\(n) items"
            case .defaultOption(let n): return "\(n) items (default)"
            }
        }

        var ptBR: String {
            switch self {
            case .all: return "Todos"
            case .favorites: return "Favoritos"
            case .searchPlaceholder: return "Buscar clipes ou apps..."
            case .noClipsFound: return "Nenhum clipe encontrado"
            case .noFavoritesYet: return "Nenhum favorito ainda"
            case .starHint: return "Marque qualquer clipe com estrela para mantê-lo aqui."
            case .copyHint: return "Copie textos, URLs ou imagens e eles aparecerão aqui."
            case .quickPaste: return "Colagem rápida"
            case .paste: return "Colar"
            case .close: return "Fechar"
            case .deleteClip: return "Apagar clipe"
            case .enableAutoPaste: return "Ativar Colagem Automática"
            case .accessibilityHelp: return "Permissão de acessibilidade necessária para colar automaticamente em aplicativos ativos"
            case .openClips: return "Abrir Clips (⌘⇧V)"
            case .allClipsMenu: return "Todos os Clipes (⌘<)"
            case .favoritesMenu: return "Favoritos (⌘1)"
            case .clearNonFavorites: return "Limpar Não Favoritos"
            case .settings: return "Configurações..."
            case .quit: return "Encerrar Clips"
            case .generalTab: return "Geral"
            case .appearanceTab: return "Aparência"
            case .language: return "Idioma"
            case .history: return "Histórico"
            case .historyLimit: return "Limite do histórico"
            case .historyLimitDescription: return "Clipes mais antigos não favoritos serão removidos automaticamente ao atingir este limite."
            case .items: return "Itens"
            case .askBeforeDeleting: return "Confirmar antes de apagar itens"
            case .accentColor: return "Cor de destaque"
            case .itemsCount(let n): return "\(n) itens"
            case .defaultOption(let n): return "\(n) itens (padrão)"
            }
        }

        var ptPT: String {
            switch self {
            case .all: return "Todos"
            case .favorites: return "Favoritos"
            case .searchPlaceholder: return "Pesquisar clipes ou apps..."
            case .noClipsFound: return "Nenhum clipe encontrado"
            case .noFavoritesYet: return "Ainda sem favoritos"
            case .starHint: return "Marque qualquer clipe com uma estrela para o manter aqui."
            case .copyHint: return "Copie texto, URLs ou imagens e aparecerão aqui."
            case .quickPaste: return "Colar rápido"
            case .paste: return "Colar"
            case .close: return "Fechar"
            case .deleteClip: return "Eliminar clipe"
            case .enableAutoPaste: return "Ativar Colagem Automática"
            case .accessibilityHelp: return "Permissão de acessibilidade necessária para colar automaticamente em aplicações ativas"
            case .openClips: return "Abrir Clips (⌘⇧V)"
            case .allClipsMenu: return "Todos os Clipes (⌘<)"
            case .favoritesMenu: return "Favoritos (⌘1)"
            case .clearNonFavorites: return "Limpar Não Favoritos"
            case .settings: return "Definições..."
            case .quit: return "Terminar Clips"
            case .generalTab: return "Geral"
            case .appearanceTab: return "Aspeto"
            case .language: return "Idioma"
            case .history: return "Histórico"
            case .historyLimit: return "Limite do histórico"
            case .historyLimitDescription: return "Clipes mais antigos que não sejam favoritos serão eliminados automaticamente ao atingir este limite."
            case .items: return "Itens"
            case .askBeforeDeleting: return "Confirmar antes de eliminar itens"
            case .accentColor: return "Cor de destaque"
            case .itemsCount(let n): return "\(n) itens"
            case .defaultOption(let n): return "\(n) itens (predefinição)"
            }
        }

        var es: String {
            switch self {
            case .all: return "Todos"
            case .favorites: return "Favoritos"
            case .searchPlaceholder: return "Buscar clips o apps..."
            case .noClipsFound: return "No se encontraron clips"
            case .noFavoritesYet: return "Aún no hay favoritos"
            case .starHint: return "Marca cualquier clip con estrella para tenerlo a mano aquí."
            case .copyHint: return "Copia texto, URLs o imágenes y aparecerán aquí."
            case .quickPaste: return "Pegado rápido"
            case .paste: return "Pegar"
            case .close: return "Cerrar"
            case .deleteClip: return "Eliminar clip"
            case .enableAutoPaste: return "Activar Pegado Automático"
            case .accessibilityHelp: return "Permiso de accesibilidad requerido para pegar automáticamente en aplicaciones activas"
            case .openClips: return "Abrir Clips (⌘⇧V)"
            case .allClipsMenu: return "Todos los Clips (⌘<)"
            case .favoritesMenu: return "Favoritos (⌘1)"
            case .clearNonFavorites: return "Limpiar No Favoritos"
            case .settings: return "Ajustes..."
            case .quit: return "Salir de Clips"
            case .generalTab: return "General"
            case .appearanceTab: return "Aspecto"
            case .language: return "Idioma"
            case .history: return "Historial"
            case .historyLimit: return "Límite del historial"
            case .historyLimitDescription: return "Los clips más antiguos no favoritos se eliminarán automáticamente al alcanzar este límite."
            case .items: return "Elementos"
            case .askBeforeDeleting: return "Preguntar antes de eliminar elementos"
            case .accentColor: return "Color de acento"
            case .itemsCount(let n): return "\(n) elementos"
            case .defaultOption(let n): return "\(n) elementos (predeterminado)"
            }
        }
    }
}

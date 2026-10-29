import Testing
@testable import ClipsKit

@Suite("L10n Localization tests")
struct L10nTests {
    @Test("All languages have non-empty translations for all core keys")
    func testAllKeysHaveTranslations() {
        let languages: [AppLanguage] = [.en, .ptBR, .ptPT, .es]

        for lang in languages {
            #expect(!L10n.tr(.all, lang: lang).isEmpty)
            #expect(!L10n.tr(.favorites, lang: lang).isEmpty)
            #expect(!L10n.tr(.searchPlaceholder, lang: lang).isEmpty)
            #expect(!L10n.tr(.quickPaste, lang: lang).isEmpty)
            #expect(!L10n.tr(.paste, lang: lang).isEmpty)
            #expect(!L10n.tr(.close, lang: lang).isEmpty)
            #expect(!L10n.tr(.deleteClip, lang: lang).isEmpty)
            #expect(!L10n.tr(.settings, lang: lang).isEmpty)
            #expect(!L10n.tr(.quit, lang: lang).isEmpty)
            #expect(!L10n.tr(.language, lang: lang).isEmpty)
            #expect(!L10n.tr(.history, lang: lang).isEmpty)
            #expect(!L10n.tr(.historyLimit, lang: lang).isEmpty)
            #expect(!L10n.tr(.hideContent, lang: lang).isEmpty)
            #expect(!L10n.tr(.hide, lang: lang).isEmpty)
            #expect(!L10n.tr(.cancel, lang: lang).isEmpty)
            #expect(!L10n.tr(.labelPlaceholder, lang: lang).isEmpty)
            #expect(!L10n.tr(.revealContent, lang: lang).isEmpty)
            #expect(!L10n.tr(.maskedTag, lang: lang).isEmpty)
            #expect(!L10n.tr(.removeLabel, lang: lang).isEmpty)
            #expect(!L10n.tr(.save, lang: lang).isEmpty)
        }
    }

    @Test("Specific regional differences between pt-BR and pt-PT")
    func testPortugueseRegionalDifferences() {
        #expect(L10n.tr(.settings, lang: .ptBR) == "Configurações...")
        #expect(L10n.tr(.settings, lang: .ptPT) == "Definições...")

        #expect(L10n.tr(.deleteClip, lang: .ptBR) == "Apagar clipe")
        #expect(L10n.tr(.deleteClip, lang: .ptPT) == "Eliminar clipe")

        #expect(L10n.tr(.quit, lang: .ptBR) == "Encerrar Clips")
        #expect(L10n.tr(.quit, lang: .ptPT) == "Terminar Clips")

        #expect(L10n.tr(.appearanceTab, lang: .ptBR) == "Aparência")
        #expect(L10n.tr(.appearanceTab, lang: .ptPT) == "Aspeto")
    }

    @Test("Spanish translations")
    func testSpanishTranslations() {
        #expect(L10n.tr(.settings, lang: .es) == "Ajustes...")
        #expect(L10n.tr(.paste, lang: .es) == "Pegar")
        #expect(L10n.tr(.quickPaste, lang: .es) == "Pegado rápido")
        #expect(L10n.tr(.close, lang: .es) == "Cerrar")
        #expect(L10n.tr(.quit, lang: .es) == "Salir de Clips")
    }
}

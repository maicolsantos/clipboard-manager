# Clips - Agent Rules & Swift Quality Standards

## Mandatory Pre-Commit Checklist (Swift Auditor)

Always execute the Swift Auditor review before making any git commit. A commit is ONLY allowed if all 5 pillars pass:

### 1. Bugs & Concurrency
- UI & Observability: All views, `@Observable` view models, and UI state mutations must be isolated to `@MainActor`.
- Safe Unwrapping: No force-unwrapping `!` on optionals without provable compile-time invariant.
- Task Lifecycle: Background `Task` instances must be cancelable and handle cancellation gracefully.
- Concurrency Safety: Types shared across concurrency boundaries must conform to `Sendable`.

### 2. Memory Leaks & ARC
- Closures: Any escaping closure or asynchronous block capturing `self` must declare `[weak self]`. Never use `[unowned self]`.
- Timers: Every `Timer` must be invalidated in cleanup or upon dismissal.
- NotificationCenter: Observers must be explicitly deregistered (`removeObserver`) or tied to an async sequence/block lifecycle.
- Large Assets / Images: Never load unconstrained full-resolution images into memory repeatedly; use downsampling (`CGImageSourceCreateThumbnailAtIndex`) and `NSCache`.

### 3. Security & Privacy
- Password Managers & Concealed Types: Filter out all concealed, transient, and password-manager clipboard data (1Password, Bitwarden, KeePassXC, LastPass, Apple Keychain).
- File System Security: Local storage directories in `Application Support` must enforce owner-only POSIX permissions (`0o700`).
- Masking: When `isMasked == true`, `preview` must return `******`. Secrets must never leak in searches, plain text previews, or log statements.

### 4. Apple Human Interface Guidelines & i18n
- Native styling: Use system styles, SF Symbols, and `Palette.accent`.
- Localized: All user-facing strings must use `L10n.tr(...)` supporting `en`, `pt-BR`, `pt-PT`, and `es`.

### 5. Automated Verification
- Run `swift test --scratch-path ~/Library/Developer/Clips/test-build` (must pass 100%).
- Run `./tools/selftest.sh` (all functional checks must pass).
- Zero compilation errors or severe warnings.

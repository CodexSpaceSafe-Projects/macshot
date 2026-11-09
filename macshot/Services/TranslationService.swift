import Foundation
import NaturalLanguage
import Combine
import SwiftUI
@preconcurrency import Translation

enum TranslationService {

    /// Whether Apple Translation is available on this system.
    static var appleTranslationAvailable: Bool {
        if #available(macOS 15.0, *) { return true }
        return false
    }

    /// Cached Apple language availability — populated on first check,
    /// reused instantly for subsequent popover opens.
    private static var cachedAppleAvailability: [String: Bool]?

    // MARK: - Target language

    static var targetLanguage: String {
        get { UserDefaults.standard.string(forKey: "translateTargetLang") ?? "en" }
        set { UserDefaults.standard.set(newValue, forKey: "translateTargetLang") }
    }

    static let availableLanguages: [(code: String, name: String)] = [
        ("en", "English"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German"),
        ("it", "Italian"),
        ("pt", "Portuguese"),
        ("nl", "Dutch"),
        ("pl", "Polish"),
        ("ru", "Russian"),
        ("zh-CN", "Chinese (Simplified)"),
        ("zh-TW", "Chinese (Traditional)"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("ar", "Arabic"),
        ("tr", "Turkish"),
        ("sv", "Swedish"),
        ("da", "Danish"),
        ("fi", "Finnish"),
        ("nb", "Norwegian"),
        ("uk", "Ukrainian"),
        ("cs", "Czech"),
        ("ro", "Romanian"),
        ("hu", "Hungarian"),
        ("sk", "Slovak"),
        ("bg", "Bulgarian"),
        ("hr", "Croatian"),
        ("id", "Indonesian"),
        ("hi", "Hindi"),
        ("th", "Thai"),
        ("vi", "Vietnamese"),
    ]

    /// Check which languages are available for Apple Translation.
    /// Returns a dict of language code → installed status.
    @available(macOS 15.0, *)
    static func checkAppleLanguageAvailability(completion: @escaping ([String: Bool]) -> Void) {
        // Return cache immediately if available
        if let cached = cachedAppleAvailability {
            completion(cached)
            return
        }

        Task {
            let availability = LanguageAvailability()
            let allLocales = availableLanguages.map { (code: $0.code, locale: appleLocale(from: $0.code)) }

            // Find the first installed pair to get a known-installed "probe" language.
            // Then check all remaining languages against that probe — O(n) instead of O(n²).
            var installed: [String: Bool] = [:]
            var probeLocale: Locale.Language?
            var probeCode: String?

            // Quick scan: find any installed pair
            outerLoop: for (i, lang) in allLocales.enumerated() {
                for other in allLocales[(i+1)...] {
                    let status = await availability.status(from: lang.locale, to: other.locale)
                    if status == .installed {
                        installed[lang.code] = true
                        installed[other.code] = true
                        probeLocale = lang.locale
                        probeCode = lang.code
                        break outerLoop
                    }
                }
            }

            // Check remaining languages against the probe
            if let probe = probeLocale, let pc = probeCode {
                for lang in allLocales where installed[lang.code] != true {
                    // Check both directions since the probe→lang direction
                    // might not be valid but lang→probe could be
                    let toStatus = await availability.status(from: probe, to: lang.locale)
                    let fromStatus = await availability.status(from: lang.locale, to: probe)
                    installed[lang.code] = (toStatus == .installed || fromStatus == .installed)
                }
                // Ensure the probe itself is marked
                installed[pc] = true
            }

            // Any language not checked stays false
            for lang in allLocales where installed[lang.code] == nil {
                installed[lang.code] = false
            }

            await MainActor.run {
                // Only cache if we found at least one installed language.
                // If the Translation framework wasn't ready (e.g. right after
                // launch), all languages come back as not-installed — don't
                // cache that or the popover stays empty for the whole session.
                if installed.values.contains(true) {
                    cachedAppleAvailability = installed
                }
                completion(installed)
            }
        }
    }

    // MARK: - Translate a batch of strings (auto-detect source)

    /// Translates text on this Mac using Apple Translation; never falls back to a network service.
    /// Calls completion on the main queue.
    static func translateBatch(
        texts: [String],
        targetLang: String,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        guard !texts.isEmpty else {
            completion(.success([]))
            return
        }

        if #available(macOS 15.0, *) {
            translateBatchApple(texts: texts, targetLang: targetLang, completion: completion)
        } else {
            DispatchQueue.main.async {
                completion(.failure(TranslationError.appleTranslation("On-device translation requires macOS 15 or later.")))
            }
        }
    }

    // MARK: - Apple Translation (macOS 15.0+ via SwiftUI bridge)

    @available(macOS 15.0, *)
    private static func translateBatchApple(
        texts: [String],
        targetLang: String,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        let target = appleLocale(from: targetLang)

        // Auto-detect source language to avoid Apple's "Choose Language" dialog
        let combined = texts.joined(separator: " ")
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(combined)

        guard let detected = recognizer.dominantLanguage else {
            // Can't detect language (single word, ambiguous text). Report on the
            // main thread — this is invoked from a background OCR queue and the
            // completion handler mutates overlay UI (the success path below also
            // hops to main).
            DispatchQueue.main.async {
                completion(.failure(TranslationError.appleTranslation("Could not detect source language. Try selecting more text.")))
            }
            return
        }

        let source = Locale.Language(identifier: detected.rawValue)
        let config = TranslationSession.Configuration(source: source, target: target)
        Task {
            let status = await LanguageAvailability().status(from: source, to: target)
            await MainActor.run {
                guard status == .installed else {
                    completion(.failure(TranslationError.appleTranslation("Install the required language packs in System Settings before using on-device translation.")))
                    return
                }
                TranslationBridge.shared.translate(texts: texts, configuration: config, completion: completion)
            }
        }
    }

    /// Map our language codes to Apple's Locale.Language.
    @available(macOS 15.0, *)
    private static func appleLocale(from code: String) -> Locale.Language {
        switch code {
        case "zh-CN": return Locale.Language(identifier: "zh-Hans")
        case "zh-TW": return Locale.Language(identifier: "zh-Hant")
        case "nb":    return Locale.Language(identifier: "no")
        default:      return Locale.Language(identifier: code)
        }
    }
}

// MARK: - SwiftUI bridge for Apple Translation

/// Uses a hidden SwiftUI view with .translationTask() to obtain a TranslationSession.
/// This is the supported way to use the Translation framework from AppKit.
@available(macOS 15.0, *)
@MainActor
final class TranslationBridge: ObservableObject {
    static let shared = TranslationBridge()

    @Published var config: TranslationSession.Configuration?
    private var hostingView: NSView?
    private var pendingTexts: [String] = []
    private var pendingCompletion: ((Result<[String], Error>) -> Void)?

    private var translationID: UUID?

    func translate(
        texts: [String],
        configuration: TranslationSession.Configuration,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        // Cancel any in-flight translation before starting a new one
        if pendingCompletion != nil {
            cleanup()
        }

        let thisID = UUID()
        translationID = thisID
        pendingTexts = texts
        pendingCompletion = completion

        // Create hidden SwiftUI view and attach to a window
        let view = TranslationBridgeView(bridge: self)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: -1, y: -1, width: 1, height: 1)
        if let window = NSApp.windows.first(where: { $0.contentView != nil }) {
            window.contentView?.addSubview(hosting)
        }
        hostingView = hosting

        // Setting config triggers .translationTask
        config = configuration

        // Timeout: if session doesn't respond in 10s, report error
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self = self, self.translationID == thisID, self.pendingCompletion != nil else { return }
            let completion = self.pendingCompletion
            self.cleanup()
            completion?(.failure(TranslationError.appleTranslation("Apple Translation timed out. The language pack may need to be downloaded in System Settings.")))
        }
    }

    fileprivate func sessionReady(_ session: TranslationSession) {
        // Ignore stale sessions from cancelled translations
        guard pendingCompletion != nil else { return }
        let texts = pendingTexts
        let completion = pendingCompletion
        let activeID = translationID
        Task {
            do {
                var results = Array(repeating: "", count: texts.count)
                for (i, text) in texts.enumerated() {
                    // Bail if a new translation was started while we're iterating
                    let stillActive = await MainActor.run { self.translationID == activeID }
                    guard stillActive else { return }
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        results[i] = text
                        continue
                    }
                    let response = try await session.translate(trimmed)
                    results[i] = response.targetText
                }
                await MainActor.run {
                    guard self.translationID == activeID else { return }
                    self.cleanup()
                    completion?(.success(results))
                }
            } catch {
                await MainActor.run {
                    guard self.translationID == activeID else { return }
                    self.cleanup()
                    let desc = error.localizedDescription
                    let msg = "Apple Translation failed: \(desc). Check the installed language packs in System Settings."
                    completion?(.failure(TranslationError.appleTranslation(msg)))
                }
            }
        }
    }

    private func cleanup() {
        hostingView?.removeFromSuperview()
        hostingView = nil
        pendingTexts = []
        pendingCompletion = nil
        config = nil
    }
}

@available(macOS 15.0, *)
private struct TranslationBridgeView: View {
    @ObservedObject var bridge: TranslationBridge

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .translationTask(bridge.config) { session in
                await MainActor.run {
                    bridge.sessionReady(session)
                }
            }
    }
}

enum TranslationError: LocalizedError {
    case appleTranslation(String)
    var errorDescription: String? {
        switch self {
        case .appleTranslation(let message): return message
        }
    }
}

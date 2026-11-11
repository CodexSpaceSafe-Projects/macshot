import Foundation

/// Retire stored configuration without touching screenshots or original takes.
enum RemovedFeatureCleanup {
    static func isRetiredSetting(_ key: String) -> Bool {
        let lower = key.lowercased()
        return key.hasPrefix("SU") || lower == "betaupdatesenabled" || lower == "translationprovider" || [
            "imgbb", "gdrive", "googledrive", "s3", "upload", "recordkeystroke", "keystroke",
        ].contains { lower.hasPrefix($0) }
    }

    static func run(defaults: UserDefaults = .standard, supportDirectory: URL? = nil) throws {
        // Preserve onboarding history before discarding obsolete updater state.
        if defaults.bool(forKey: "SUHasLaunchedBefore") {
            defaults.set(true, forKey: "screenRecordingGrantedBefore")
        }
        for key in defaults.dictionaryRepresentation().keys where isRetiredSetting(key) {
            defaults.removeObject(forKey: key)
        }
        guard let support = supportDirectory ?? FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let tokens = support.appendingPathComponent("com.sw33tlie.macshot/gdrive_tokens.json")
        if FileManager.default.fileExists(atPath: tokens.path) {
            try FileManager.default.removeItem(at: tokens)
        }
    }
}

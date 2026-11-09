import Foundation
import XCTest

final class RemovedFeatureCleanupTests: XCTestCase {
    func testRetiredConfigurationCannotBeImportedOrExported() {
        for key in ["uploadProvider", "imgbbUploads", "gdriveFolderName", "s3Endpoint",
                    "recordKeystroke", "keystrokeShowAll", "translationProvider"] {
            XCTAssertTrue(RemovedFeatureCleanup.isRetiredSetting(key))
            XCTAssertFalse(SettingsPortability.isPortable(key))
        }
        XCTAssertFalse(RemovedFeatureCleanup.isRetiredSetting("recordMouseHighlight"))
        XCTAssertTrue(SettingsPortability.isPortable("translateTargetLang"))
    }

    func testCleanupDeletesOldCredentialsAndPreservesUnrelatedData() throws {
        let suite = "macshot-retirement-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let support = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: support) }
        let app = support.appendingPathComponent("com.sw33tlie.macshot")
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        let tokens = app.appendingPathComponent("gdrive_tokens.json")
        let recording = app.appendingPathComponent("original.mp4")
        try Data("obsolete credential".utf8).write(to: tokens)
        try Data("keep".utf8).write(to: recording)
        defaults.set("secret", forKey: "s3SecretAccessKey")
        defaults.set(true, forKey: "recordKeystroke")
        defaults.set(true, forKey: "recordMouseHighlight")

        try RemovedFeatureCleanup.run(defaults: defaults, supportDirectory: support)
        try RemovedFeatureCleanup.run(defaults: defaults, supportDirectory: support)

        XCTAssertNil(defaults.object(forKey: "s3SecretAccessKey"))
        XCTAssertNil(defaults.object(forKey: "recordKeystroke"))
        XCTAssertTrue(defaults.bool(forKey: "recordMouseHighlight"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: tokens.path))
        XCTAssertEqual(try Data(contentsOf: recording), Data("keep".utf8))
    }
}

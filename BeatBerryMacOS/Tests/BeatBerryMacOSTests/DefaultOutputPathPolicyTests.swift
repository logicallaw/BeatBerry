/*
 * This is file of the project BeatBerry
 * Licensed under the GNU General Public License v3.0.
 * Copyright (c) 2025-2026 BeatBerry
 * For full license text, see the LICENSE file in the root directory or at
 * https://www.gnu.org/licenses/gpl-3.0.txt
 * Author: Junho Kim
 * Latest Updated Date: 2026-02-28
 */

import XCTest
import BeatBerryDomain
import BeatBerryInfrastructure

final class DefaultOutputPathPolicyTests: XCTestCase {
    func testCollisionCreatesIndexedFileName() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("beatberry-output-path-policy-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let input = tempDir.appendingPathComponent("song.wav")
        try Data("dummy".utf8).write(to: input)

        let outputDir = tempDir.appendingPathComponent("outputs")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        try Data("exists".utf8).write(to: outputDir.appendingPathComponent("song.mp3"))

        let policy = DefaultOutputPathPolicy()
        let settings = ConversionSettings(targetFormat: .mp3, outputDirectory: outputDir)

        let url = try policy.makeOutputURL(for: input, settings: settings)
        XCTAssertEqual(url.lastPathComponent, "song (1).mp3")
    }
}

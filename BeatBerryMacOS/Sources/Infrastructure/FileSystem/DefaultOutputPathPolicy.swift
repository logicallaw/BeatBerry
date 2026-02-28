/*
 * This is file of the project BeatBerry
 * Licensed under the GNU General Public License v3.0.
 * Copyright (c) 2025-2026 BeatBerry
 * For full license text, see the LICENSE file in the root directory or at
 * https://www.gnu.org/licenses/gpl-3.0.txt
 * Author: Junho Kim
 * Latest Updated Date: 2026-02-28
 */

import Foundation
import BeatBerryDomain

public struct DefaultOutputPathPolicy: OutputPathPolicy {
    public init() {}

    public func makeOutputURL(for inputURL: URL, settings: ConversionSettings) throws -> URL {
        let fileManager = FileManager.default
        let root = settings.outputDirectory
            ?? inputURL.deletingLastPathComponent().appendingPathComponent("outputs")
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)

        let base = inputURL.deletingPathExtension().lastPathComponent
        let ext = settings.targetFormat.rawValue
        let candidate = root.appendingPathComponent("\(base).\(ext)")
        return uniqueOutputURL(for: candidate, fileManager: fileManager)
    }

    private func uniqueOutputURL(for preferred: URL, fileManager: FileManager) -> URL {
        if !fileManager.fileExists(atPath: preferred.path) {
            return preferred
        }

        let ext = preferred.pathExtension
        let base = preferred.deletingPathExtension().lastPathComponent
        let dir = preferred.deletingLastPathComponent()

        var index = 1
        while true {
            let candidate = dir.appendingPathComponent("\(base) (\(index)).\(ext)")
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            index += 1
        }
    }
}

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

public struct ScanFolderUseCase: Sendable {
    private let fileScanner: any FileScanner
    private let supportedExtensions: Set<String>

    public init(
        fileScanner: any FileScanner,
        supportedExtensions: Set<String> = ["m4a", "mp3", "wav", "flac", "ogg", "wma"]
    ) {
        self.fileScanner = fileScanner
        self.supportedExtensions = supportedExtensions
    }

    public func execute(folderURL: URL) throws -> [URL] {
        try fileScanner.scanFiles(in: folderURL)
            .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
    }
}

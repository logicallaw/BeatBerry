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

public enum AudioFormat: String, CaseIterable, Identifiable, Sendable {
    case mp3, wav, flac, ogg, m4a

    public var id: String { rawValue }
}

public struct ConversionSettings: Sendable {
    public var targetFormat: AudioFormat
    public var outputDirectory: URL?

    public init(targetFormat: AudioFormat = .mp3, outputDirectory: URL? = nil) {
        self.targetFormat = targetFormat
        self.outputDirectory = outputDirectory
    }
}

public struct ConversionJob: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let inputURL: URL

    public var displayName: String { inputURL.lastPathComponent }

    public init(inputURL: URL) {
        self.inputURL = inputURL
    }
}

public struct ConversionResult: Identifiable, Sendable {
    public enum Status: Sendable {
        case success(outputURL: URL)
        case failure(reason: String)
    }

    public let id = UUID()
    public let inputURL: URL
    public let status: Status

    public init(inputURL: URL, status: Status) {
        self.inputURL = inputURL
        self.status = status
    }
}

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

public enum MediaFormat: String, CaseIterable, Identifiable, Sendable {
    case mp3, wav, flac, ogg, m4a
    case mp4

    public var id: String { rawValue }

    public var mediaType: MediaType {
        switch self {
        case .mp3, .wav, .flac, .ogg, .m4a:
            return .audio
        case .mp4:
            return .video
        }
    }
}

public enum MediaType: Sendable {
    case audio
    case video
}

public struct ConversionSettings: Sendable {
    public var targetFormat: MediaFormat
    public var outputDirectory: URL?

    public init(targetFormat: MediaFormat = .mp3, outputDirectory: URL? = nil) {
        self.targetFormat = targetFormat
        self.outputDirectory = outputDirectory
    }
}

public struct ConversionJob: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let inputURL: URL

    public var displayName: String { inputURL.lastPathComponent }

    public var mediaType: MediaType {
        let ext = inputURL.pathExtension.lowercased()
        let videoExtensions: Set<String> = ["webm", "mp4", "avi", "mov", "mkv", "m4v", "mpeg", "mpg"]

        if videoExtensions.contains(ext) {
            return .video
        }
        return .audio
    }

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

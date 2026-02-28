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

public struct FFmpegAudioConverter: AudioConverter {
    private let ffmpegURLProvider: @Sendable () -> URL?
    private let outputPathPolicy: any OutputPathPolicy

    public init(
        ffmpegURLProvider: @escaping @Sendable () -> URL? = { FFmpegPathResolver.resolve() },
        outputPathPolicy: any OutputPathPolicy = DefaultOutputPathPolicy()
    ) {
        self.ffmpegURLProvider = ffmpegURLProvider
        self.outputPathPolicy = outputPathPolicy
    }

    public func convert(job: ConversionJob, settings: ConversionSettings) async -> ConversionResult {
        guard let ffmpegURL = ffmpegURLProvider() else {
            return ConversionResult(
                inputURL: job.inputURL,
                status: .failure(reason: "Cannot find ffmpeg executable.")
            )
        }

        let outputURL: URL
        do {
            outputURL = try outputPathPolicy.makeOutputURL(for: job.inputURL, settings: settings)
        } catch {
            return ConversionResult(
                inputURL: job.inputURL,
                status: .failure(reason: "Failed to create output path: \(error.localizedDescription)")
            )
        }

        let process = Process()
        process.executableURL = ffmpegURL
        process.arguments = [
            "-y",
            "-i", job.inputURL.path,
            outputURL.path
        ]

        let stdErr = Pipe()
        process.standardError = stdErr

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ConversionResult(
                inputURL: job.inputURL,
                status: .failure(reason: "Failed to run ffmpeg: \(error.localizedDescription)")
            )
        }

        if process.terminationStatus == 0 {
            return ConversionResult(inputURL: job.inputURL, status: .success(outputURL: outputURL))
        }

        let errorData = stdErr.fileHandleForReading.readDataToEndOfFile()
        let message = normalizeFFmpegError(errorData: errorData, terminationStatus: process.terminationStatus)
        return ConversionResult(inputURL: job.inputURL, status: .failure(reason: message))
    }

    private func normalizeFFmpegError(errorData: Data, terminationStatus: Int32) -> String {
        let raw = String(data: errorData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lowered = raw.lowercased()

        let mappedPrefix: String
        if lowered.contains("no such file or directory") {
            mappedPrefix = "Input file not found."
        } else if lowered.contains("permission denied") {
            mappedPrefix = "Permission denied while accessing file."
        } else if lowered.contains("invalid data found") || lowered.contains("invalid argument") {
            mappedPrefix = "Unsupported or corrupted audio file."
        } else if lowered.contains("unknown encoder") || lowered.contains("could not find encoder") {
            mappedPrefix = "Encoder for the selected output format was not found."
        } else {
            mappedPrefix = "ffmpeg conversion failed"
        }

        guard !raw.isEmpty else {
            return "\(mappedPrefix) (exit code: \(terminationStatus))"
        }

        let maxLength = 500
        let detail = raw.count > maxLength ? "\(raw.prefix(maxLength))..." : raw
        return "\(mappedPrefix) (exit code: \(terminationStatus))\nDetails: \(detail)"
    }
}

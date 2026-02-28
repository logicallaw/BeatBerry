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

public enum FFmpegPathResolver {
    public static func resolve() -> URL? {
        let fileManager = FileManager.default

        if let envPath = ProcessInfo.processInfo.environment["BEATBERRY_FFMPEG_PATH"],
           fileManager.isExecutableFile(atPath: envPath) {
            return URL(fileURLWithPath: envPath)
        }

        let runtimeCandidates: [URL?] = [
            Bundle.main.url(forResource: "ffmpeg", withExtension: nil),
            Bundle.main.resourceURL?.appendingPathComponent("ffmpeg"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/ffmpeg"),
            URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().appendingPathComponent("ffmpeg")
        ]

        for candidate in runtimeCandidates {
            guard let path = candidate?.path else { continue }
            if fileManager.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        // Development fallback. Release builds should ship bundled ffmpeg.
        let fallbackPaths = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]

        for path in fallbackPaths where fileManager.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
}

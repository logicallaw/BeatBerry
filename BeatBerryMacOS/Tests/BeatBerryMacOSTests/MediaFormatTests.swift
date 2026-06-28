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

final class MediaFormatTests: XCTestCase {
    func testMediaTypeForAudioFormats() {
        XCTAssertEqual(MediaFormat.mp3.mediaType, .audio)
        XCTAssertEqual(MediaFormat.wav.mediaType, .audio)
        XCTAssertEqual(MediaFormat.flac.mediaType, .audio)
        XCTAssertEqual(MediaFormat.ogg.mediaType, .audio)
        XCTAssertEqual(MediaFormat.m4a.mediaType, .audio)
    }

    func testMediaTypeForVideoFormats() {
        XCTAssertEqual(MediaFormat.mp4.mediaType, .video)
    }

    func testConversionJobDetectsAudioFiles() {
        let audioExtensions = ["mp3", "wav", "flac", "ogg", "m4a", "wma"]

        for ext in audioExtensions {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("test.\(ext)")
            let job = ConversionJob(inputURL: tempURL)

            XCTAssertEqual(
                job.mediaType,
                .audio,
                "File with extension '\(ext)' should be detected as audio"
            )
        }
    }

    func testConversionJobDetectsVideoFiles() {
        let videoExtensions = ["webm", "mp4", "avi", "mov", "mkv", "m4v", "mpeg", "mpg"]

        for ext in videoExtensions {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("test.\(ext)")
            let job = ConversionJob(inputURL: tempURL)

            XCTAssertEqual(
                job.mediaType,
                .video,
                "File with extension '\(ext)' should be detected as video"
            )
        }
    }

    func testConversionJobIsCaseInsensitive() {
        let uppercaseWebm = FileManager.default.temporaryDirectory
            .appendingPathComponent("test.WEBM")
        let lowercaseWebm = FileManager.default.temporaryDirectory
            .appendingPathComponent("test.webm")
        let mixedWebm = FileManager.default.temporaryDirectory
            .appendingPathComponent("test.WeBm")

        XCTAssertEqual(ConversionJob(inputURL: uppercaseWebm).mediaType, .video)
        XCTAssertEqual(ConversionJob(inputURL: lowercaseWebm).mediaType, .video)
        XCTAssertEqual(ConversionJob(inputURL: mixedWebm).mediaType, .video)
    }

    func testUnknownExtensionDefaultsToAudio() {
        let unknownURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test.unknown")
        let job = ConversionJob(inputURL: unknownURL)

        XCTAssertEqual(job.mediaType, .audio)
    }
}

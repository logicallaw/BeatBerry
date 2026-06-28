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
import BeatBerryApplication
import BeatBerryPresentation

@MainActor
final class ConversionViewModelTests: XCTestCase {
    private var viewModel: ConversionViewModel!

    override func setUp() async throws {
        let addFilesUseCase = AddFilesUseCase()
        let fileScanner = MockFileScanner()
        let scanFolderUseCase = ScanFolderUseCase(fileScanner: fileScanner)
        let converter = MockConverter()
        let convertBatchUseCase = ConvertBatchUseCase(converter: converter)
        let cancellation = ConversionCancellation()

        viewModel = ConversionViewModel(
            addFilesUseCase: addFilesUseCase,
            scanFolderUseCase: scanFolderUseCase,
            convertBatchUseCase: convertBatchUseCase,
            cancellation: cancellation
        )
    }

    func testAvailableFormatsForAudioOnly() {
        let audioURLs = [
            URL(fileURLWithPath: "/tmp/test1.mp3"),
            URL(fileURLWithPath: "/tmp/test2.wav")
        ]

        viewModel.addFiles(audioURLs)

        let available = viewModel.availableFormats
        XCTAssertEqual(Set(available), Set([.mp3, .wav, .flac, .ogg, .m4a]))
        XCTAssertFalse(available.contains(.mp4))
    }

    func testAvailableFormatsForVideoOnly() {
        let videoURLs = [
            URL(fileURLWithPath: "/tmp/test1.webm"),
            URL(fileURLWithPath: "/tmp/test2.mp4")
        ]

        viewModel.addFiles(videoURLs)

        let available = viewModel.availableFormats
        XCTAssertEqual(available, [.mp4])
    }

    func testAvailableFormatsForMixedFiles() {
        let mixedURLs = [
            URL(fileURLWithPath: "/tmp/audio.mp3"),
            URL(fileURLWithPath: "/tmp/video.webm")
        ]

        viewModel.addFiles(mixedURLs)

        let available = viewModel.availableFormats
        XCTAssertEqual(Set(available), Set(MediaFormat.allCases))
    }

    func testTargetFormatAutoAdjustsWhenAddingVideoFiles() {
        // Start with audio
        viewModel.addFiles([URL(fileURLWithPath: "/tmp/audio.mp3")])
        XCTAssertEqual(viewModel.settings.targetFormat, .mp3)

        // Clear and add video
        viewModel.clearSelection()
        viewModel.addFiles([URL(fileURLWithPath: "/tmp/video.webm")])

        // Should auto-adjust to mp4
        XCTAssertEqual(viewModel.settings.targetFormat, .mp4)
    }

    func testTargetFormatRemainsValidWhenAddingAudioFiles() {
        // Start with video
        viewModel.addFiles([URL(fileURLWithPath: "/tmp/video.webm")])
        XCTAssertEqual(viewModel.settings.targetFormat, .mp4)

        // Clear and add audio
        viewModel.clearSelection()
        viewModel.addFiles([URL(fileURLWithPath: "/tmp/audio.mp3")])

        // Should auto-adjust to mp3 (first audio format)
        XCTAssertEqual(viewModel.settings.targetFormat, .mp3)
    }

    func testTargetFormatPreservedWhenValid() {
        viewModel.addFiles([URL(fileURLWithPath: "/tmp/test.mp3")])
        viewModel.settings.targetFormat = .wav

        // Add another audio file
        viewModel.addFiles([URL(fileURLWithPath: "/tmp/test2.mp3")])

        // Should preserve wav since it's still valid
        XCTAssertEqual(viewModel.settings.targetFormat, .wav)
    }

    func testSelectedCountTextForAudioOnly() {
        viewModel.addFiles([
            URL(fileURLWithPath: "/tmp/test1.mp3"),
            URL(fileURLWithPath: "/tmp/test2.wav")
        ])

        XCTAssertEqual(viewModel.selectedCountText, "2 files selected")
    }

    func testSelectedCountTextForVideoOnly() {
        viewModel.addFiles([
            URL(fileURLWithPath: "/tmp/test1.webm"),
            URL(fileURLWithPath: "/tmp/test2.mp4")
        ])

        XCTAssertEqual(viewModel.selectedCountText, "2 files selected")
    }

    func testSelectedCountTextForMixedFiles() {
        viewModel.addFiles([
            URL(fileURLWithPath: "/tmp/audio1.mp3"),
            URL(fileURLWithPath: "/tmp/audio2.wav"),
            URL(fileURLWithPath: "/tmp/video1.webm")
        ])

        XCTAssertEqual(viewModel.selectedCountText, "3 files selected (2 audio, 1 video)")
    }

    func testClearSelectionResetsFormat() {
        viewModel.addFiles([URL(fileURLWithPath: "/tmp/video.webm")])
        XCTAssertEqual(viewModel.settings.targetFormat, .mp4)

        viewModel.clearSelection()
        XCTAssertEqual(viewModel.settings.targetFormat, .mp3)
    }
}

// MARK: - Mock Classes

private final class MockFileScanner: FileScanner {
    func scanFiles(in folderURL: URL) throws -> [URL] {
        return []
    }
}

private final class MockConverter: AudioConverter {
    func convert(job: ConversionJob, settings: ConversionSettings) async -> ConversionResult {
        let baseName = job.inputURL.deletingPathExtension().lastPathComponent
        let outputURL = settings.outputDirectory?
            .appendingPathComponent("\(baseName).\(settings.targetFormat.rawValue)")
            ?? job.inputURL.deletingLastPathComponent()
                .appendingPathComponent("\(baseName).\(settings.targetFormat.rawValue)")

        return ConversionResult(inputURL: job.inputURL, status: .success(outputURL: outputURL))
    }
}

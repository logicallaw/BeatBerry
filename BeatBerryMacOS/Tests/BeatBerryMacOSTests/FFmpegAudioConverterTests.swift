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

final class FFmpegAudioConverterTests: XCTestCase {
    func testConvertSingleFileWithExecutableEngineSuccess() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("beatberry-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fakeFFmpeg = tempDir.appendingPathComponent("fake-ffmpeg.sh")
        try makeFakeConverterExecutable(at: fakeFFmpeg)

        let inputWav = tempDir.appendingPathComponent("input.wav")
        try Data("dummy".utf8).write(to: inputWav)

        let outputDir = tempDir.appendingPathComponent("outputs")
        let engine = FFmpegAudioConverter(ffmpegURLProvider: { fakeFFmpeg })
        let settings = ConversionSettings(targetFormat: .mp3, outputDirectory: outputDir)
        let job = ConversionJob(inputURL: inputWav)

        let result = await engine.convert(job: job, settings: settings)

        switch result.status {
        case .success(let outputURL):
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
            XCTAssertEqual(outputURL.pathExtension.lowercased(), "mp3")
            XCTAssertEqual(outputURL.lastPathComponent, "input.mp3")
        case .failure(let reason):
            XCTFail("Conversion failed: \(reason)")
        }
    }

    func testOutputCollisionCreatesUniqueFileName() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("beatberry-collision-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fakeFFmpeg = tempDir.appendingPathComponent("fake-ffmpeg.sh")
        try makeFakeConverterExecutable(at: fakeFFmpeg)

        let inputWav = tempDir.appendingPathComponent("input.wav")
        try Data("dummy".utf8).write(to: inputWav)

        let outputDir = tempDir.appendingPathComponent("outputs")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        let existing = outputDir.appendingPathComponent("input.mp3")
        try Data("already-exists".utf8).write(to: existing)

        let engine = FFmpegAudioConverter(ffmpegURLProvider: { fakeFFmpeg })
        let settings = ConversionSettings(targetFormat: .mp3, outputDirectory: outputDir)
        let job = ConversionJob(inputURL: inputWav)

        let result = await engine.convert(job: job, settings: settings)

        switch result.status {
        case .success(let outputURL):
            XCTAssertEqual(outputURL.lastPathComponent, "input (1).mp3")
            XCTAssertTrue(FileManager.default.fileExists(atPath: existing.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        case .failure(let reason):
            XCTFail("Collision handling failed: \(reason)")
        }
    }

    func testConvertSingleFileToMp3WithRealFFmpegIfAvailable() async throws {
        guard let ffmpeg = FFmpegPathResolver.resolve() else {
            throw XCTSkip("Skipping real conversion test: ffmpeg executable not found.")
        }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("beatberry-real-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let inputWav = tempDir.appendingPathComponent("input.wav")
        try generateInputWav(ffmpegURL: ffmpeg, output: inputWav)

        let outputDir = tempDir.appendingPathComponent("outputs")
        let engine = FFmpegAudioConverter(ffmpegURLProvider: { ffmpeg })
        let settings = ConversionSettings(targetFormat: .mp3, outputDirectory: outputDir)
        let job = ConversionJob(inputURL: inputWav)

        let result = await engine.convert(job: job, settings: settings)

        switch result.status {
        case .success(let outputURL):
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
            XCTAssertEqual(outputURL.pathExtension.lowercased(), "mp3")
        case .failure(let reason):
            XCTFail("Real conversion failed: \(reason)")
        }
    }

    func testFailureMessageWhenFFmpegMissing() async {
        let engine = FFmpegAudioConverter(ffmpegURLProvider: { nil })
        let tempInput = FileManager.default.temporaryDirectory.appendingPathComponent("missing.wav")
        let settings = ConversionSettings(targetFormat: .mp3, outputDirectory: nil)
        let job = ConversionJob(inputURL: tempInput)

        let result = await engine.convert(job: job, settings: settings)

        switch result.status {
        case .success:
            XCTFail("Expected failure when ffmpeg is missing.")
        case .failure(let reason):
            XCTAssertTrue(reason.contains("ffmpeg executable"))
        }
    }

    func testFailureMessageMapsPermissionDeniedAndTruncates() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("beatberry-failure-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let failingFFmpeg = tempDir.appendingPathComponent("fake-fail-ffmpeg.sh")
        try makeFailingExecutable(at: failingFFmpeg)

        let inputWav = tempDir.appendingPathComponent("input.wav")
        try Data("dummy".utf8).write(to: inputWav)

        let outputDir = tempDir.appendingPathComponent("outputs")
        let engine = FFmpegAudioConverter(ffmpegURLProvider: { failingFFmpeg })
        let settings = ConversionSettings(targetFormat: .mp3, outputDirectory: outputDir)
        let job = ConversionJob(inputURL: inputWav)

        let result = await engine.convert(job: job, settings: settings)

        switch result.status {
        case .success:
            XCTFail("Expected failure from failing script.")
        case .failure(let reason):
            XCTAssertTrue(reason.contains("Permission denied while accessing file."))
            XCTAssertTrue(reason.contains("exit code: 1"))
            XCTAssertLessThan(reason.count, 700)
        }
    }

    private func makeFakeConverterExecutable(at path: URL) throws {
        let script = """
        #!/bin/sh
        input=""
        output=""
        prev=""
        for arg in "$@"; do
          if [ "$prev" = "-i" ]; then
            input="$arg"
          fi
          output="$arg"
          prev="$arg"
        done
        if [ -n "$input" ]; then
          cp "$input" "$output" 2>/dev/null || touch "$output"
        else
          touch "$output"
        fi
        exit 0
        """

        try script.write(to: path, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path.path)
    }

    private func makeFailingExecutable(at path: URL) throws {
        let script = """
        #!/bin/sh
        i=0
        while [ $i -lt 100 ]; do
          echo "Permission denied: cannot access output target due to policy lock $i" 1>&2
          i=$((i + 1))
        done
        exit 1
        """
        try script.write(to: path, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path.path)
    }

    private func generateInputWav(ffmpegURL: URL, output: URL) throws {
        let process = Process()
        process.executableURL = ffmpegURL
        process.arguments = [
            "-y",
            "-f", "lavfi",
            "-i", "anullsrc=r=44100:cl=stereo",
            "-t", "1",
            output.path
        ]

        let errPipe = Pipe()
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let data = errPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8) ?? "Failed to generate input wav with ffmpeg"
            XCTFail(message)
        }
    }
}

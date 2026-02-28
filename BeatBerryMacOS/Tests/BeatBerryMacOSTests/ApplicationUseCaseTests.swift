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
import BeatBerryApplication
import BeatBerryDomain

final class ApplicationUseCaseTests: XCTestCase {
    func testAddFilesUseCaseRemovesDuplicates() {
        let existing = [
            ConversionJob(inputURL: URL(fileURLWithPath: "/tmp/a.wav"))
        ]
        let adding = [
            URL(fileURLWithPath: "/tmp/a.wav"),
            URL(fileURLWithPath: "/tmp/b.wav"),
            URL(fileURLWithPath: "/tmp/c.wav")
        ]

        let result = AddFilesUseCase().execute(existingJobs: existing, addingURLs: adding)

        XCTAssertEqual(result.addedCount, 2)
        XCTAssertEqual(result.jobs.count, 3)
        XCTAssertEqual(result.jobs.map(\.inputURL.path), ["/tmp/a.wav", "/tmp/b.wav", "/tmp/c.wav"])
    }

    func testConvertBatchUseCaseAggregatesSuccessAndFailureCounts() async {
        let jobs = [
            ConversionJob(inputURL: URL(fileURLWithPath: "/tmp/ok-1.wav")),
            ConversionJob(inputURL: URL(fileURLWithPath: "/tmp/fail-1.wav")),
            ConversionJob(inputURL: URL(fileURLWithPath: "/tmp/ok-2.wav"))
        ]
        let converter = MockAudioConverter { job in
            if job.inputURL.lastPathComponent.hasPrefix("fail") {
                return .failure(reason: "mock failure")
            }
            return .success(outputURL: URL(fileURLWithPath: "/tmp/out-\(job.inputURL.lastPathComponent).mp3"))
        }

        let useCase = ConvertBatchUseCase(converter: converter)
        let cancellation = ConversionCancellation()
        let result = await useCase.execute(
            jobs: jobs,
            settings: ConversionSettings(targetFormat: .mp3),
            cancellation: cancellation
        )

        XCTAssertEqual(result.processedCount, 3)
        XCTAssertEqual(result.successCount, 2)
        XCTAssertEqual(result.failureCount, 1)
        XCTAssertFalse(result.cancelled)
    }

    func testConvertBatchUseCaseStopsWhenCancellationRequested() async {
        let jobs = [
            ConversionJob(inputURL: URL(fileURLWithPath: "/tmp/1.wav")),
            ConversionJob(inputURL: URL(fileURLWithPath: "/tmp/2.wav")),
            ConversionJob(inputURL: URL(fileURLWithPath: "/tmp/3.wav"))
        ]
        let converter = MockAudioConverter(delayNanos: 120_000_000) { job in
            .success(outputURL: URL(fileURLWithPath: "/tmp/out-\(job.inputURL.lastPathComponent).mp3"))
        }

        let useCase = ConvertBatchUseCase(converter: converter)
        let cancellation = ConversionCancellation()

        Task {
            try? await Task.sleep(nanoseconds: 40_000_000)
            await cancellation.request()
        }

        let result = await useCase.execute(
            jobs: jobs,
            settings: ConversionSettings(targetFormat: .mp3),
            cancellation: cancellation
        )

        XCTAssertEqual(result.processedCount, 1)
        XCTAssertEqual(result.successCount, 1)
        XCTAssertEqual(result.failureCount, 0)
        XCTAssertTrue(result.cancelled)
    }
}

private struct MockAudioConverter: AudioConverter {
    let delayNanos: UInt64
    let resultFactory: @Sendable (ConversionJob) -> ConversionResult.Status

    init(
        delayNanos: UInt64 = 0,
        resultFactory: @escaping @Sendable (ConversionJob) -> ConversionResult.Status
    ) {
        self.delayNanos = delayNanos
        self.resultFactory = resultFactory
    }

    func convert(job: ConversionJob, settings: ConversionSettings) async -> ConversionResult {
        if delayNanos > 0 {
            try? await Task.sleep(nanoseconds: delayNanos)
        }
        return ConversionResult(inputURL: job.inputURL, status: resultFactory(job))
    }
}

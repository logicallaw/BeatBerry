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

public actor ConversionCancellation {
    private var requested = false

    public init() {}

    public func request() {
        requested = true
    }

    public func reset() {
        requested = false
    }

    public func isRequested() -> Bool {
        requested
    }
}

public struct BatchConversionRecord: Sendable {
    public let index: Int
    public let total: Int
    public let job: ConversionJob
    public let result: ConversionResult

    public init(index: Int, total: Int, job: ConversionJob, result: ConversionResult) {
        self.index = index
        self.total = total
        self.job = job
        self.result = result
    }
}

public struct ConvertBatchResult: Sendable {
    public let records: [BatchConversionRecord]
    public let successCount: Int
    public let failureCount: Int
    public let processedCount: Int
    public let cancelled: Bool

    public init(
        records: [BatchConversionRecord],
        successCount: Int,
        failureCount: Int,
        processedCount: Int,
        cancelled: Bool
    ) {
        self.records = records
        self.successCount = successCount
        self.failureCount = failureCount
        self.processedCount = processedCount
        self.cancelled = cancelled
    }
}

public struct ConvertBatchUseCase: Sendable {
    private let converter: any AudioConverter

    public init(converter: any AudioConverter) {
        self.converter = converter
    }

    public func execute(
        jobs: [ConversionJob],
        settings: ConversionSettings,
        cancellation: ConversionCancellation,
        onRecord: @MainActor @Sendable (BatchConversionRecord) -> Void = { _ in }
    ) async -> ConvertBatchResult {
        var records: [BatchConversionRecord] = []
        var successCount = 0
        var failureCount = 0
        var cancelled = false

        for (offset, job) in jobs.enumerated() {
            if await cancellation.isRequested() {
                cancelled = true
                break
            }

            let index = offset + 1
            let result = await converter.convert(job: job, settings: settings)
            let record = BatchConversionRecord(index: index, total: jobs.count, job: job, result: result)
            records.append(record)
            await onRecord(record)

            switch result.status {
            case .success:
                successCount += 1
            case .failure:
                failureCount += 1
            }
        }

        return ConvertBatchResult(
            records: records,
            successCount: successCount,
            failureCount: failureCount,
            processedCount: records.count,
            cancelled: cancelled
        )
    }
}

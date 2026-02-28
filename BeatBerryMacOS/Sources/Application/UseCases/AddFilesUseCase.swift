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

public struct AddFilesResult: Sendable {
    public let jobs: [ConversionJob]
    public let addedCount: Int

    public init(jobs: [ConversionJob], addedCount: Int) {
        self.jobs = jobs
        self.addedCount = addedCount
    }
}

public struct AddFilesUseCase: Sendable {
    public init() {}

    public func execute(existingJobs: [ConversionJob], addingURLs: [URL]) -> AddFilesResult {
        let existingSet = Set(existingJobs.map(\.inputURL))
        let newJobs = addingURLs
            .filter { !existingSet.contains($0) }
            .map { ConversionJob(inputURL: $0) }

        return AddFilesResult(jobs: existingJobs + newJobs, addedCount: newJobs.count)
    }
}

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
import BeatBerryApplication
import BeatBerryDomain

struct ConversionSummary: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let message: String
}

@MainActor
public final class ConversionViewModel: ObservableObject {
    @Published var selectedJobs: [ConversionJob] = []
    @Published var settings = ConversionSettings()
    @Published var isConverting = false
    @Published var isCancellationRequested = false
    @Published var logs: [String] = []
    @Published var successCount = 0
    @Published var failureCount = 0
    @Published var processedCount = 0
    @Published var totalCount = 0
    @Published var summary: ConversionSummary?

    private let addFilesUseCase: AddFilesUseCase
    private let scanFolderUseCase: ScanFolderUseCase
    private let convertBatchUseCase: ConvertBatchUseCase
    private let cancellation: ConversionCancellation

    var availableFormats: [AudioFormat] { AudioFormat.allCases }
    var selectedCountText: String { "\(selectedJobs.count) files selected" }
    var outputPathText: String { settings.outputDirectory?.path ?? "outputs folder next to each input file" }
    var isStartDisabled: Bool { isConverting }
    var isCancelDisabled: Bool { !isConverting }
    var shouldShowProgress: Bool { isConverting || processedCount > 0 }
    var progressText: String { "Progress: \(processedCount)/\(max(totalCount, 1))" }
    var progressValue: Double {
        guard totalCount > 0 else { return 0 }
        return Double(processedCount) / Double(totalCount)
    }

    public init(
        addFilesUseCase: AddFilesUseCase,
        scanFolderUseCase: ScanFolderUseCase,
        convertBatchUseCase: ConvertBatchUseCase,
        cancellation: ConversionCancellation
    ) {
        self.addFilesUseCase = addFilesUseCase
        self.scanFolderUseCase = scanFolderUseCase
        self.convertBatchUseCase = convertBatchUseCase
        self.cancellation = cancellation
    }

    func addFiles(_ urls: [URL]) {
        let result = addFilesUseCase.execute(existingJobs: selectedJobs, addingURLs: urls)
        selectedJobs = result.jobs
        log("Added \(result.addedCount) file(s).")
    }

    func addFolder(_ folderURL: URL) {
        do {
            let urls = try scanFolderUseCase.execute(folderURL: folderURL)
            addFiles(urls)
            log("Collected \(urls.count) file(s) from folder: \(folderURL.path)")
        } catch {
            log("Unable to read folder: \(folderURL.path)")
        }
    }

    func clearSelection() {
        selectedJobs.removeAll()
        log("Selection cleared.")
    }

    func setOutputDirectory(_ url: URL?) {
        settings.outputDirectory = url
        if let url {
            log("Output folder selected: \(url.path)")
        } else {
            log("Output folder unset: using outputs next to each input file")
        }
    }

    func requestCancellation() {
        guard isConverting else { return }
        isCancellationRequested = true
        Task {
            await cancellation.request()
        }
        log("Cancellation requested: the batch will stop after the current file.")
    }

    func convertAll() async {
        guard !selectedJobs.isEmpty else {
            log("No files to convert.")
            return
        }

        isConverting = true
        isCancellationRequested = false
        await cancellation.reset()
        successCount = 0
        failureCount = 0
        processedCount = 0
        totalCount = selectedJobs.count
        summary = nil
        log("--- Starting .\(settings.targetFormat.rawValue) conversion ---")

        let result = await convertBatchUseCase.execute(
            jobs: selectedJobs,
            settings: settings,
            cancellation: cancellation
        ) { record in
            processedCount = record.index
            log("[\(record.index)/\(record.total)] Processing: \(record.job.displayName)")
            switch record.result.status {
            case .success(let outputURL):
                successCount += 1
                log("  -> Saved: \(outputURL.path)")
            case .failure(let reason):
                failureCount += 1
                log("  -> Error: \(reason)")
            }
        }

        if result.cancelled {
            log("Batch conversion stopped by user request.")
        }

        successCount = result.successCount
        failureCount = result.failureCount
        processedCount = result.processedCount
        let cancelled = result.cancelled
        let title = cancelled ? "Conversion Stopped" : "Conversion Completed"
        let summaryMessage = "Processed: \(processedCount)\nSucceeded: \(successCount)\nFailed: \(failureCount)"
        log("--- \(title): succeeded \(successCount), failed \(failureCount) ---")

        summary = ConversionSummary(title: title, message: summaryMessage)
        isConverting = false
        isCancellationRequested = false
        totalCount = 0
        selectedJobs.removeAll()
    }

    private func log(_ message: String) {
        logs.append(message)
    }
}

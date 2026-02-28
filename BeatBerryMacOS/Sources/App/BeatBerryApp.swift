/*
 * This is file of the project BeatBerry
 * Licensed under the GNU General Public License v3.0.
 * Copyright (c) 2025-2026 BeatBerry
 * For full license text, see the LICENSE file in the root directory or at
 * https://www.gnu.org/licenses/gpl-3.0.txt
 * Author: Junho Kim
 * Latest Updated Date: 2026-02-28
 */

import SwiftUI
import BeatBerryPresentation
import BeatBerryInfrastructure
import BeatBerryApplication

@MainActor
@main
struct BeatBerryApp: App {
    private let viewModel: ConversionViewModel

    init() {
        let converter = FFmpegAudioConverter()
        let fileScanner = LocalFileScanner()
        let addFilesUseCase = AddFilesUseCase()
        let scanFolderUseCase = ScanFolderUseCase(fileScanner: fileScanner)
        let convertBatchUseCase = ConvertBatchUseCase(converter: converter)
        let cancellation = ConversionCancellation()
        self.viewModel = ConversionViewModel(
            addFilesUseCase: addFilesUseCase,
            scanFolderUseCase: scanFolderUseCase,
            convertBatchUseCase: convertBatchUseCase,
            cancellation: cancellation
        )
    }

    var body: some Scene {
        WindowGroup("BeatBerry") {
            ContentView(viewModel: viewModel)
        }
    }
}

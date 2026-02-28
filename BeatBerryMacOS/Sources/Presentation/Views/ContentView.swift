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
import AppKit
import UniformTypeIdentifiers

public struct ContentView: View {
    @StateObject private var viewModel: ConversionViewModel

    public init(viewModel: ConversionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            BeatBerryTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    inputCard
                    actionCard

                    if viewModel.shouldShowProgress {
                        progressCard
                    }

                    selectedFilesCard
                    logsCard
                }
                .padding(20)
            }
        }
        .frame(minWidth: 820, minHeight: 560)
        .alert(item: $viewModel.summary) { summary in
            Alert(
                title: Text(summary.title),
                message: Text(summary.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var headerCard: some View {
        BeatBerryCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("BeatBerry")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(BeatBerryTheme.textPrimary)

                Text("Fast batch audio conversion with a clean workflow.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BeatBerryTheme.textSecondary)

                Text(viewModel.selectedCountText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BeatBerryTheme.accent)
            }
        }
    }

    private var inputCard: some View {
        BeatBerryCard {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Button("Select Files") { selectFiles() }
                        .buttonStyle(BeatBerrySecondaryButtonStyle())

                    Button("Select Folder") { selectFolder() }
                        .buttonStyle(BeatBerrySecondaryButtonStyle())

                    Button("Output Folder") { selectOutputFolder() }
                        .buttonStyle(BeatBerrySecondaryButtonStyle())

                    Button("Clear") { viewModel.clearSelection() }
                        .buttonStyle(BeatBerryGhostButtonStyle())
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Output Path")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BeatBerryTheme.textSecondary)

                    Text(viewModel.outputPathText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BeatBerryTheme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Target Format", selection: $viewModel.settings.targetFormat) {
                    ForEach(viewModel.availableFormats) { format in
                        Text(format.rawValue.uppercased()).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var actionCard: some View {
        BeatBerryCard {
            HStack(spacing: 10) {
                Button(viewModel.isConverting ? "Converting..." : "Start Conversion") {
                    Task { await viewModel.convertAll() }
                }
                .buttonStyle(BeatBerryPrimaryButtonStyle())
                .disabled(viewModel.isStartDisabled)

                Button("Cancel") {
                    viewModel.requestCancellation()
                }
                .buttonStyle(BeatBerrySecondaryButtonStyle())
                .disabled(viewModel.isCancelDisabled)
            }
        }
    }

    private var progressCard: some View {
        BeatBerryCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.progressText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BeatBerryTheme.textPrimary)

                ProgressView(value: viewModel.progressValue)
                    .tint(BeatBerryTheme.accent)
            }
        }
    }

    private var selectedFilesCard: some View {
        BeatBerryCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Selected Files")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(BeatBerryTheme.textPrimary)

                if viewModel.selectedJobs.isEmpty {
                    Text("No files selected.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BeatBerryTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(viewModel.selectedJobs) { job in
                                Text(job.displayName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(BeatBerryTheme.textPrimary)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(maxHeight: 180)
                }
            }
        }
    }

    private var logsCard: some View {
        BeatBerryCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Logs")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(BeatBerryTheme.textPrimary)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(viewModel.logs.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(BeatBerryTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(minHeight: 120, maxHeight: 220)
            }
        }
    }

    private struct BeatBerryCard<Content: View>: View {
        @ViewBuilder let content: Content

        var body: some View {
            VStack {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BeatBerryTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(BeatBerryTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private struct BeatBerryPrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(configuration.isPressed ? BeatBerryTheme.accentPressed : BeatBerryTheme.accent)
                )
        }
    }

    private struct BeatBerrySecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BeatBerryTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(configuration.isPressed ? BeatBerryTheme.surfacePressed : BeatBerryTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(BeatBerryTheme.border, lineWidth: 1)
                )
        }
    }

    private struct BeatBerryGhostButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(configuration.isPressed ? BeatBerryTheme.accentPressed : BeatBerryTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
    }

    private enum BeatBerryTheme {
        static let accent = Color(red: 1.0, green: 57.0 / 255.0, blue: 57.0 / 255.0)
        static let accentPressed = Color(red: 0.86, green: 0.15, blue: 0.15)
        static let background = Color.white
        static let surface = Color.white
        static let surfacePressed = Color(red: 0.96, green: 0.96, blue: 0.96)
        static let border = Color.black.opacity(0.08)
        static let textPrimary = Color.black
        static let textSecondary = Color.black.opacity(0.58)
    }

    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.audio]

        if panel.runModal() == .OK {
            viewModel.addFiles(panel.urls)
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.addFolder(url)
        }
    }

    private func selectOutputFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.setOutputDirectory(url)
        }
    }
}

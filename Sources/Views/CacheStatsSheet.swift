import SwiftUI

public struct CacheStatsSheet: View {
    @ObservedObject var viewModel: FolderTreeViewModel
    @ObservedObject private var l10n = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var cacheSizeBytes: Int64 = 0

    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.cacheSheetTitle)
                        .font(.headline)
                    Text(l10n.cacheSheetSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            Divider()

            VStack(spacing: 12) {
                HStack {
                    Text(l10n.cacheFoldersCount)
                    Spacer()
                    Text("\(viewModel.cachedItemsCount)")
                        .bold()
                }

                HStack {
                    Text(l10n.cacheFileSizeOnDisk)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: cacheSizeBytes, countStyle: .file))
                        .bold()
                }

                Divider()

                HStack {
                    Text(l10n.languageLabel)
                    Spacer()
                    Picker("", selection: $l10n.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)

            VStack(spacing: 10) {
                Button {
                    viewModel.recalculateEntireCache()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(l10n.recalculateAllCachedFolders)
                    }
                    .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    viewModel.clearAllCache()
                    cacheSizeBytes = 0
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text(l10n.clearCache)
                    }
                    .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
            }

            Spacer()

            HStack {
                Spacer()
                Button(l10n.close) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440, height: 350)
        .task {
            cacheSizeBytes = await SizeCacheManager.shared.cacheFileSizeBytes()
        }
    }
}


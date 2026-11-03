import SwiftUI

public struct FileRowView: View {
    @ObservedObject var node: FileNode
    let level: Int
    @ObservedObject var viewModel: FolderTreeViewModel

    @State private var isHovered: Bool = false

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Indentation
                if level > 0 {
                    Spacer()
                        .frame(width: CGFloat(level * 20))
                }

                // Disclosure button for directories
                if node.isDirectory {
                    Button {
                        viewModel.toggleExpand(node: node)
                    } label: {
                        Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer()
                        .frame(width: 16)
                }

                // File/folder icon
                Image(nsImage: node.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)

                // Name
                Text(node.name)
                    .font(.system(size: 13, weight: node.isDirectory ? .medium : .regular))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(.primary)

                Spacer()

                // Cache indicator badge (for directories)
                if node.isDirectory {
                    if node.isCalculating {
                        HStack(spacing: 4) {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.7)
                            Text(viewModel.l10n.calculating)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(4)
                    } else if node.isCached {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            if let cachedTime = node.formattedCachedTime {
                                Text(viewModel.l10n.cachedTimeAgo(cachedTime))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            } else {
                                Text(viewModel.l10n.cachedBadge)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(4)
                        .help(viewModel.l10n.cacheHelp)
                    }
                }

                // Item count for directories
                if node.isDirectory, let count = node.itemCount {
                    Text(viewModel.l10n.itemsCount(count))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 65, alignment: .trailing)
                } else if node.isDirectory {
                    Text("—")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.5))
                        .frame(width: 65, alignment: .trailing)
                } else {
                    Spacer()
                        .frame(width: 65)
                }

                // Size
                Text(node.formattedSize)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(node.isDirectory ? .primary : .secondary)
                    .frame(width: 85, alignment: .trailing)

                // Recalculate button for folders
                if node.isDirectory {
                    Button {
                        viewModel.calculateFolderSize(node: node, forceRecalculate: true)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(node.isCalculating ? .secondary : .accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(node.isCalculating)
                    .help(viewModel.l10n.recalculateThisFolder)
                    .frame(width: 24, height: 24)
                    .opacity(isHovered || node.isCalculating ? 1.0 : 0.4)
                } else {
                    Spacer()
                        .frame(width: 24)
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(
                viewModel.selectedNode?.id == node.id
                    ? Color.accentColor.opacity(0.2)
                    : (isHovered ? Color.primary.opacity(0.04) : Color.clear)
            )
            .cornerRadius(6)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                viewModel.selectedNode = node
            }
            .simultaneousGesture(TapGesture(count: 2).onEnded {
                if node.isDirectory {
                    viewModel.toggleExpand(node: node)
                }
            })
            .contextMenu {
                if node.isDirectory {
                    Button {
                        viewModel.calculateFolderSize(node: node, forceRecalculate: true)
                    } label: {
                        Label(viewModel.l10n.recalculateSize, systemImage: "arrow.clockwise")
                    }

                    Divider()
                }

                Button {
                    viewModel.revealInFinder(node: node)
                } label: {
                    Label(viewModel.l10n.showInFinder, systemImage: "folder")
                }

                Button {
                    viewModel.openInTerminal(node: node)
                } label: {
                    Label(viewModel.l10n.openInTerminal, systemImage: "terminal")
                }

                Divider()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(node.url.path, forType: .string)
                } label: {
                    Label(viewModel.l10n.copyPath, systemImage: "doc.on.doc")
                }
            }

            // Expanded children
            if node.isExpanded, let children = node.children {
                let visibleChildren = viewModel.showFiles ? children : children.filter { $0.isDirectory }
                ForEach(visibleChildren) { child in
                    FileRowView(node: child, level: level + 1, viewModel: viewModel)
                }
            }
        }
    }
}


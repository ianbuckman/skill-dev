import SwiftUI

struct HistoryView: View {
    @State private var items: [CaptureHistoryItem] = []
    @State private var filterType: CaptureType?
    @State private var historyService = HistoryService()

    var body: some View {
        VStack(spacing: 0) {
            FilterBar()
            Divider()
            ItemList()
        }
        .frame(minWidth: 400, minHeight: 300)
        .task {
            loadItems()
        }
    }

    @ViewBuilder
    private func FilterBar() -> some View {
        HStack {
            Text("Capture History")
                .font(.headline)

            Spacer()

            Picker("Filter", selection: $filterType) {
                Text("All").tag(nil as CaptureType?)
                ForEach(CaptureType.allCases) { type in
                    Label(type.rawValue, systemImage: type.systemImage)
                        .tag(type as CaptureType?)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .onChange(of: filterType) { _, _ in loadItems() }

            Button("Clear All") {
                historyService.clearHistory()
                items.removeAll()
            }
            .foregroundStyle(.red)
        }
        .padding(12)
    }

    @ViewBuilder
    private func ItemList() -> some View {
        if items.isEmpty {
            ContentUnavailableView(
                "No Captures",
                systemImage: "camera.slash",
                description: Text("Your capture history will appear here")
            )
        } else {
            List {
                ForEach(items) { item in
                    HistoryItemRow(item: item)
                        .contextMenu {
                            Button("Open") {
                                NSWorkspace.shared.open(URL(fileURLWithPath: item.filePath))
                            }
                            Button("Show in Finder") {
                                NSWorkspace.shared.selectFile(item.filePath, inFileViewerRootedAtPath: "")
                            }
                            Button("Copy to Clipboard") {
                                if let image = NSImage(contentsOfFile: item.filePath) {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.writeObjects([image])
                                }
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                historyService.removeItem(id: item.id)
                                loadItems()
                            }
                        }
                }
            }
        }
    }

    private func loadItems() {
        items = historyService.filterHistory(by: filterType)
    }
}

struct HistoryItemRow: View {
    let item: CaptureHistoryItem

    var body: some View {
        HStack(spacing: 12) {
            ThumbnailView()
            InfoView()
            Spacer()
            TypeBadge()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func ThumbnailView() -> some View {
        if let path = item.thumbnailPath, let image = NSImage(contentsOfFile: path) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Image(systemName: item.type.systemImage)
                .frame(width: 48, height: 36)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    @ViewBuilder
    private func InfoView() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(URL(fileURLWithPath: item.filePath).lastPathComponent)
                .font(.caption)
                .lineLimit(1)
            Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func TypeBadge() -> some View {
        Text(item.type.rawValue)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.15))
            .clipShape(Capsule())
    }
}

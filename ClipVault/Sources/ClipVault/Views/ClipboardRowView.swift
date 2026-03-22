import AppKit
import SwiftUI

struct ClipboardRowView: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            // Left: content type icon + pin indicator
            ZStack(alignment: .bottomTrailing) {
                contentTypeIcon
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)

                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.yellow)
                        .offset(x: 4, y: 4)
                }
            }

            // Middle: content preview
            contentPreview
                .frame(maxWidth: .infinity, alignment: .leading)

            // Right: timestamp or action buttons
            if isHovered {
                HStack(spacing: 4) {
                    Button {
                        onTogglePin()
                    } label: {
                        Image(systemName: item.isPinned ? "pin.slash" : "pin")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help(item.isPinned ? "Unpin" : "Pin")

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete")
                }
            } else {
                Text(item.timestamp, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovering in
            isHovered = hovering
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onCopy()
        }
    }

    // MARK: - Content Type Icon

    @ViewBuilder
    private var contentTypeIcon: some View {
        switch item.content {
        case .text:
            Image(systemName: "doc.plaintext")
        case .image:
            Image(systemName: "photo")
        }
    }

    // MARK: - Content Preview

    @ViewBuilder
    private var contentPreview: some View {
        switch item.content {
        case .text(let string):
            Text(string)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.tail)

        case .image(let data):
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Text("Image (\(data.count) bytes)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

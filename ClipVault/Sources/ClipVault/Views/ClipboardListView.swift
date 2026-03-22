import SwiftUI

struct ClipboardListView: View {
    @Bindable var appState: AppState
    @State private var showClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Title Bar
            titleBar

            Divider()

            // MARK: - Search Bar
            searchBar
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            // MARK: - List or Empty State
            if appState.filteredItems.isEmpty {
                emptyState
            } else {
                itemList
            }

            Divider()

            // MARK: - Bottom Toolbar
            bottomToolbar
        }
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack {
            Text("ClipVault")
                .font(.headline)

            Spacer()

            SettingsLink {
                Image(systemName: "gearshape")
                    .font(.body)
            }
            .buttonStyle(.borderless)
            .help("Settings")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.callout)

            TextField("Search...", text: $appState.searchText)
                .textFieldStyle(.plain)
                .font(.callout)

            if !appState.searchText.isEmpty {
                Button {
                    appState.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Item List

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(appState.filteredItems) { item in
                    ClipboardRowView(
                        item: item,
                        onCopy: { appState.copyToClipboard(item) },
                        onTogglePin: { appState.togglePin(item) },
                        onDelete: { appState.delete(item) }
                    )

                    if item.id != appState.filteredItems.last?.id {
                        Divider()
                            .padding(.horizontal, 8)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()

            if appState.searchText.isEmpty {
                Image(systemName: "clipboard")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
                Text("No clipboard history yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("Copy something to get started")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Image(systemName: "magnifyingglass")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
                Text("No results found")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("Try a different search term")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack {
            Text("\(appState.items.count) items")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Clear All") {
                showClearConfirmation = true
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .foregroundStyle(.secondary)
            .alert("Clear all unpinned items?", isPresented: $showClearConfirmation) {
                Button("Clear All", role: .destructive) {
                    appState.clearAll()
                }
                Button("Cancel", role: .cancel) {}
            }

            Button("Quit") {
                appState.flushAndQuit()
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

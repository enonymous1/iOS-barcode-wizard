import SwiftUI

/// Saved items. v1's list showed only the description, never
/// reloaded after its async read, and had no delete path. This
/// list shows description (or barcode), company, and size, is
/// searchable, supports swipe-to-delete, and refreshes from the
/// store on appear and on pull-to-refresh.
struct ItemListView: View {
    @Bindable var viewModel: ItemListViewModel

    var body: some View {
        NavigationStack {
            Group {
                if let error = viewModel.errorMessage,
                   viewModel.items.isEmpty {
                    ContentUnavailableView {
                        Label(
                            "Couldn't load items",
                            systemImage: "exclamationmark.triangle"
                        )
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Try Again") {
                            Task { await viewModel.load() }
                        }
                    }
                } else if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView("Loading items")
                } else if viewModel.filteredItems.isEmpty {
                    ContentUnavailableView {
                        Label("No items yet", systemImage: "barcode")
                    } description: {
                        if viewModel.searchText.isEmpty {
                            Text(
                                "Scan a barcode on the Scan tab "
                                    + "to save your first item."
                            )
                        } else {
                            Text("No items match your search.")
                        }
                    }
                } else {
                    List {
                        ForEach(viewModel.filteredItems) { item in
                            NavigationLink {
                                ItemDetailView(
                                    item: item,
                                    listViewModel: viewModel
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.displayTitle)
                                        .font(.headline)
                                    if !item.company.isEmpty {
                                        Text(item.company)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    if !item.size.isEmpty {
                                        Text(item.size)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await viewModel.delete(
                                        viewModel.filteredItems[index]
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Items")
            .searchable(
                text: $viewModel.searchText,
                prompt: "Search code, company, or description"
            )
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
        }
    }
}

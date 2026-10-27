import Foundation
import Observation

/// The saved-items list. v1 fired its Firestore read in
/// `viewDidLoad`, never reloaded the table when the read finished,
/// and passed whatever had arrived by segue time to the list
/// screen, so the list was usually empty. Here the list owns its
/// load: it fetches, then publishes, and the view renders the
/// result, a loading state, or an error with a retry button.
@MainActor
@Observable
final class ItemListViewModel {
    var items: [ProductItem] = []
    var searchText = ""
    var isLoading = false
    var errorMessage: String?

    private let store: any ItemStore
    private let userID: String

    init(store: any ItemStore, userID: String) {
        self.store = store
        self.userID = userID
    }

    var filteredItems: [ProductItem] {
        guard !searchText.isEmpty else { return items }
        let needle = searchText.lowercased()
        return items.filter {
            $0.code.lowercased().contains(needle)
                || $0.company.lowercased().contains(needle)
                || $0.description.lowercased().contains(needle)
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await store.fetchItems(userID: userID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ item: ProductItem) async {
        do {
            try await store.deleteItem(item, userID: userID)
            items.removeAll { $0.code == item.code }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(_ item: ProductItem) async {
        do {
            try await store.saveItem(item, userID: userID)
            var list = items
            list.removeAll { $0.code == item.code }
            list.append(item)
            items = list.sorted { $0.displayTitle < $1.displayTitle }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

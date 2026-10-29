import FirebaseFirestore
import Foundation

/// Persistence for scanned items, behind a protocol so the list
/// view model and tests can use an in-memory store.
///
/// Layout: `users/{uid}/items/{barcode}`. v1 stored items in a
/// collection named after the user's email address and never
/// wrote anything at all; v2 writes on save and keys by UID.
/// Items saved by v1 (under an email-named collection) are not
/// migrated automatically — see the README's migration note.
protocol ItemStore: Sendable {
    func fetchItems(userID: String) async throws -> [ProductItem]
    func saveItem(_ item: ProductItem, userID: String) async throws
    func deleteItem(_ item: ProductItem, userID: String) async throws
}

/// Cloud Firestore, using the Codable support in
/// FirebaseFirestore (the separate FirebaseFirestoreSwift product
/// was merged into it in Firebase 11 and does not exist in the
/// 12.x SDK). The document ID is the barcode, so
/// saving the same item twice overwrites it instead of creating
/// a duplicate row.
final class FirebaseItemStore: ItemStore, @unchecked Sendable {
    private func collection(userID: String) -> CollectionReference {
        Firestore.firestore()
            .collection("users").document(userID).collection("items")
    }

    func fetchItems(userID: String) async throws -> [ProductItem] {
        let snapshot = try await collection(userID: userID).getDocuments()
        return try snapshot.documents.map { document in
            var item = try document.data(as: ProductItem.self)
            // The document ID is authoritative: a stored record
            // whose `code` field disagrees with its ID still
            // loads under the barcode it was saved as.
            item = ProductItem(
                code: document.documentID,
                company: item.company,
                description: item.description,
                imageURL: item.imageURL,
                size: item.size
            )
            return item
        }
        .sorted { $0.displayTitle < $1.displayTitle }
    }

    func saveItem(_ item: ProductItem, userID: String) async throws {
        try collection(userID: userID).document(item.code)
            .setData(from: item)
    }

    func deleteItem(_ item: ProductItem, userID: String) async throws {
        try await collection(userID: userID).document(item.code).delete()
    }
}

/// In-memory store for previews and tests.
final class InMemoryItemStore: ItemStore, @unchecked Sendable {
    private var items: [String: [ProductItem]] = [:]

    init(items: [ProductItem] = []) {
        self.items["test-user"] = items
    }

    func fetchItems(userID: String) async throws -> [ProductItem] {
        items[userID] ?? []
    }

    func saveItem(_ item: ProductItem, userID: String) async throws {
        var list = items[userID] ?? []
        list.removeAll { $0.code == item.code }
        list.append(item)
        items[userID] = list
    }

    func deleteItem(_ item: ProductItem, userID: String) async throws {
        items[userID]?.removeAll { $0.code == item.code }
    }
}

import SwiftUI

/// One item, viewed and edited. v1's detail screen force-unwrapped
/// the image URL and every label, never stopped its spinner on
/// error, and its edit button only printed to the console. This
/// screen uses AsyncImage with a placeholder, shows the barcode
/// verbatim, and edits company/description/size in a form that
/// saves back to the store. Items that came from a failed lookup
/// open here in edit mode with a banner, so "not found" becomes
/// "enter it yourself" instead of a dead end.
struct ItemDetailView: View {
    let item: ProductItem
    let listViewModel: ItemListViewModel

    @State private var company: String
    @State private var description: String
    @State private var size: String
    @State private var isEditing: Bool
    @State private var isSaving = false

    init(item: ProductItem, listViewModel: ItemListViewModel) {
        self.item = item
        self.listViewModel = listViewModel
        _company = State(initialValue: item.company)
        _description = State(initialValue: item.description)
        _size = State(initialValue: item.size)
        _isEditing = State(initialValue: item.isPlaceholder)
    }

    var body: some View {
        Form {
            if let urlString = item.imageURL,
               let url = URL(string: urlString) {
                Section {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                        case .failure:
                            Label(
                                "Image unavailable",
                                systemImage: "photo.slash"
                            )
                            .foregroundStyle(.secondary)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Section("Barcode") {
                Text(item.code)
                    .font(.headline)
                    .textSelection(.enabled)
            }

            if item.isPlaceholder && isEditing {
                Section {
                    Text(
                        "No product was found for this barcode. "
                            + "Fill in the details below and save it."
                    )
                    .foregroundStyle(.secondary)
                }
            }

            Section("Details") {
                if isEditing {
                    TextField("Company", text: $company)
                    TextField("Description", text: $description)
                    TextField("Size", text: $size)
                } else {
                    LabeledContent("Company", value: companyOrPlaceholder)
                    LabeledContent(
                        "Description",
                        value: descriptionOrPlaceholder
                    )
                    LabeledContent("Size", value: sizeOrPlaceholder)
                }
            }

            Section {
                if isEditing {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(isSaving)
                    Button("Cancel", role: .cancel) {
                        company = item.company
                        description = item.description
                        size = item.size
                        isEditing = false
                    }
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
        .navigationTitle(item.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var companyOrPlaceholder: String {
        company.isEmpty ? "—" : company
    }

    private var descriptionOrPlaceholder: String {
        description.isEmpty ? "—" : description
    }

    private var sizeOrPlaceholder: String {
        size.isEmpty ? "—" : size
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let updated = ProductItem(
            code: item.code,
            company: company,
            description: description,
            imageURL: item.imageURL,
            size: size
        )
        await listViewModel.save(updated)
        isEditing = false
    }
}

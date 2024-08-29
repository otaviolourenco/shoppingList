//
//  ContentView.swift
//  shoppingList
//
//  Created by Otavio Lourenço on 29/08/2024.
//
import SwiftUI

struct Item: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var price: Double
    var isSelected: Bool = false
    
    init(id: UUID = UUID(), name: String, price: Double, isSelected: Bool = false) {
        self.id = id
        self.name = name
        self.price = price
        self.isSelected = isSelected
    }
}

struct ShoppingList: Identifiable, Codable {
    let id: UUID
    var name: String
    var items: [Item]
    
    init(id: UUID = UUID(), name: String, items: [Item] = []) {
        self.id = id
        self.name = name
        self.items = items
    }
}

class ShoppingListViewModel: ObservableObject {
    @Published var shoppingLists: [ShoppingList] = []
    
    init() {
        loadLists()
    }
    
    func addList(name: String) {
        let newList = ShoppingList(name: name)
        shoppingLists.append(newList)
        saveLists()
    }
    
    func deleteList(at offsets: IndexSet) {
        shoppingLists.remove(atOffsets: offsets)
        saveLists()
    }
    
    func addItem(to list: ShoppingList, name: String, price: Double) {
        if let index = shoppingLists.firstIndex(where: { $0.id == list.id }) {
            shoppingLists[index].items.append(Item(name: name, price: price))
            saveLists()
        }
    }
    
    func deleteItem(from list: ShoppingList, at offsets: IndexSet) {
        if let index = shoppingLists.firstIndex(where: { $0.id == list.id }) {
            shoppingLists[index].items.remove(atOffsets: offsets)
            saveLists()
        }
    }
    
    func updateItem(in list: ShoppingList, item: Item) {
        if let listIndex = shoppingLists.firstIndex(where: { $0.id == list.id }),
           let itemIndex = shoppingLists[listIndex].items.firstIndex(where: { $0.id == item.id }) {
            shoppingLists[listIndex].items[itemIndex] = item
            saveLists()
        }
    }
    
    private func saveLists() {
        if let encoded = try? JSONEncoder().encode(shoppingLists) {
            UserDefaults.standard.set(encoded, forKey: "ShoppingLists")
        }
    }
    
    private func loadLists() {
        if let savedLists = UserDefaults.standard.data(forKey: "ShoppingLists"),
           let decodedLists = try? JSONDecoder().decode([ShoppingList].self, from: savedLists) {
            shoppingLists = decodedLists
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ShoppingListViewModel()
    @State private var showingAddList = false
    @State private var newListName = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.shoppingLists) { list in
                    NavigationLink(destination: ListDetailView(viewModel: viewModel, list: list)) {
                        Text(list.name)
                    }
                }
                .onDelete(perform: viewModel.deleteList)
            }
            .navigationTitle("Shopping Lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddList = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddList) {
                AddListView(isPresented: $showingAddList, viewModel: viewModel)
            }
        }
    }
}

struct ListDetailView: View {
    @ObservedObject var viewModel: ShoppingListViewModel
    let list: ShoppingList
    @State private var newItemName = ""
    @State private var newItemPrice = ""
    
    var body: some View {
        VStack {
            List {
                ForEach(list.items) { item in
                    ItemRow(item: item, onUpdate: { updatedItem in
                        viewModel.updateItem(in: list, item: updatedItem)
                    })
                }
                .onDelete { offsets in
                    viewModel.deleteItem(from: list, at: offsets)
                }
            }
            
            VStack {
                HStack {
                    TextField("Item name", text: $newItemName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Price", text: $newItemPrice)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
                
                Button(action: addItem) {
                    Text("Add Item")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(newItemName.isEmpty || newItemPrice.isEmpty)
            }
            .padding()
            
            VStack {
                Text("Total: € \(totalPrice, specifier: "%.2f")")
                    .font(.headline)
                Text("Selected total: € \(selectedItemsPrice, specifier: "%.2f")")
                    .font(.subheadline)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .navigationTitle(list.name)
    }
    
    private var totalPrice: Double {
        list.items.reduce(0) { $0 + $1.price }
    }
    
    private var selectedItemsPrice: Double {
        list.items.filter { $0.isSelected }.reduce(0) { $0 + $1.price }
    }
    
    private func addItem() {
        if let price = Double(newItemPrice.replacingOccurrences(of: ",", with: ".")) {
            viewModel.addItem(to: list, name: newItemName, price: price)
            newItemName = ""
            newItemPrice = ""
        }
    }
}

struct ItemRow: View {
    @State var item: Item
    let onUpdate: (Item) -> Void
    @State private var tempPrice: String = ""
    
    var body: some View {
        HStack {
            TextField("Item name", text: $item.name, onCommit: updateItem)
            Spacer()
            TextField("Price", text: $tempPrice, onEditingChanged: { began in
                if !began {
                    updateItem()
                }
            })
            .onAppear {
                tempPrice = String(format: "%.2f", item.price).replacingOccurrences(of: ".", with: ",")
            }
            .keyboardType(.decimalPad)
            .frame(width: 70)
            Toggle("", isOn: $item.isSelected)
                .onChange(of: item.isSelected) { _, _ in updateItem() }
        }
    }
    
    private func updateItem() {
        if let newPrice = Double(tempPrice.replacingOccurrences(of: ",", with: ".")) {
            item.price = newPrice
        }
        onUpdate(item)
    }
}

struct AddListView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ShoppingListViewModel
    @State private var listName = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("List Name", text: $listName)
            }
            .navigationTitle("New Shopping List")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.addList(name: listName)
                        isPresented = false
                    }
                    .disabled(listName.isEmpty)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

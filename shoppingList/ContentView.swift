//
//  ContentView.swift
//  shoppingList
//
//  Created by Otavio Lourenço on 29/08/2024.
//
import SwiftUI

enum PriceType: String, Codable {
    case unit = "Unit"
    case weight = "Weight"
}

struct Item: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var priceType: PriceType
    var unitPrice: Double
    var quantity: Double
    var weight: Double?
    var isSelected: Bool = false
    
    var totalPrice: Double {
        switch priceType {
        case .unit:
            return unitPrice * quantity
        case .weight:
            return unitPrice * (weight ?? 0) / 1000 // Convert grams to kg
        }
    }
    
    init(id: UUID = UUID(), name: String, priceType: PriceType, unitPrice: Double, quantity: Double = 1, weight: Double? = nil, isSelected: Bool = false) {
        self.id = id
        self.name = name
        self.priceType = priceType
        self.unitPrice = unitPrice
        self.quantity = quantity
        self.weight = priceType == .weight ? weight : nil
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
    
    func addItem(to list: ShoppingList, item: Item) {
        if let index = shoppingLists.firstIndex(where: { $0.id == list.id }) {
            shoppingLists[index].items.append(item)
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
    @State private var showingAddItem = false
    
    var body: some View {
        VStack {
            List {
                ForEach($viewModel.shoppingLists[viewModel.shoppingLists.firstIndex(where: { $0.id == list.id })!].items) { $item in
                    ItemRow(viewModel: viewModel, list: list, item: $item)
                }
                .onDelete { offsets in
                    viewModel.deleteItem(from: list, at: offsets)
                }
            }
            
            VStack {
                Button(action: { showingAddItem = true }) {
                    Text("Add Item")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
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
        .sheet(isPresented: $showingAddItem) {
            AddItemView(isPresented: $showingAddItem, viewModel: viewModel, list: list)
        }
    }
    
    private var totalPrice: Double {
        list.items.reduce(0) { $0 + $1.totalPrice }
    }
    
    private var selectedItemsPrice: Double {
        list.items.filter { $0.isSelected }.reduce(0) { $0 + $1.totalPrice }
    }
}

struct EditItemView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ShoppingListViewModel
    let list: ShoppingList
    @Binding var item: Item
    @State private var weightString: String

    init(isPresented: Binding<Bool>, viewModel: ShoppingListViewModel, list: ShoppingList, item: Binding<Item>) {
        self._isPresented = isPresented
        self.viewModel = viewModel
        self.list = list
        self._item = item
        self._weightString = State(initialValue: item.wrappedValue.weight.map { String($0) } ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Item Name", text: $item.name)

                Picker("Price Type", selection: $item.priceType) {
                    Text("Unit").tag(PriceType.unit)
                    Text("Weight").tag(PriceType.weight)
                }
                .pickerStyle(SegmentedPickerStyle())

                TextField("Unit Price", value: $item.unitPrice, format: .number)
                    .keyboardType(.decimalPad)

                if item.priceType == .unit {
                    TextField("Quantity", value: $item.quantity, format: .number)
                        .keyboardType(.numberPad)
                } else {
                    TextField("Weight (grams)", text: $weightString)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if item.priceType == .unit {
                            item.weight = nil
                        } else {
                            item.weight = Double(weightString)
                        }
                        viewModel.updateItem(in: list, item: item)
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct ItemRow: View {
    @ObservedObject var viewModel: ShoppingListViewModel
    let list: ShoppingList
    @Binding var item: Item
    @State private var showingEditItem = false

    var body: some View {
        HStack {
                Button(action: {
                    showingEditItem = true
                }) {
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.headline)

                        HStack {
                            Text("Unit price: € \(item.unitPrice, specifier: "%.2f")")
                            Spacer()
                            if item.priceType == .unit {
                                Text("Quantity: \(Int(item.quantity))")
                            } else {
                                Text("Weight: \(item.weight ?? 0, specifier: "%.0f")g")
                            }
                        }
                        .font(.subheadline)

                        Text("Total: € \(item.totalPrice, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

            Toggle("", isOn: $item.isSelected)
                            .onChange(of: item.isSelected) { _, _ in
                                viewModel.updateItem(in: list, item: item)
                            }
                    }
                    .sheet(isPresented: $showingEditItem) {
                        EditItemView(isPresented: $showingEditItem, viewModel: viewModel, list: list, item: $item)
                    }
                }
            }

struct AddItemView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ShoppingListViewModel
    let list: ShoppingList
    
    @State private var name = ""
    @State private var priceType: PriceType = .unit
    @State private var unitPrice = ""
    @State private var quantity = "1"
    @State private var weight = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Item Name", text: $name)
                
                Picker("Price Type", selection: $priceType) {
                    Text("Unit").tag(PriceType.unit)
                    Text("Weight").tag(PriceType.weight)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                TextField("Unit Price", text: $unitPrice)
                    .keyboardType(.decimalPad)
                
                if priceType == .unit {
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                } else {
                    TextField("Weight (grams)", text: $weight)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                                            if let price = Double(unitPrice.replacingOccurrences(of: ",", with: ".")),
                                               let qty = Double(quantity) {
                                                let weightValue = priceType == .weight ? Double(weight) : nil
                                                let newItem = Item(name: name, priceType: priceType, unitPrice: price, quantity: qty, weight: weightValue)
                                                viewModel.addItem(to: list, item: newItem)
                                                isPresented = false
                                            }
                                        }
                    .disabled(name.isEmpty || unitPrice.isEmpty || (priceType == .unit && quantity.isEmpty) || (priceType == .weight && weight.isEmpty))
                }
            }
        }
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

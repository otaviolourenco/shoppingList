//
//  ContentView.swift
//  shoppingList
//
//  Created by Otavio Lourenço on 29/08/2024.
//

import SwiftUI

struct Item: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var price: Double
    var isSelected: Bool = false
}

class ShoppingListViewModel: ObservableObject {
    @Published var items: [Item] = []
    
    var totalPrice: Double {
        items.reduce(0) { $0 + $1.price }
    }
    
    var selectedItemsPrice: Double {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.price }
    }
    
    func addItem(name: String, price: Double) {
        let newItem = Item(name: name, price: price)
        items.append(newItem)
    }
    
    func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    func updateItem(_ item: Item) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ShoppingListViewModel()
    @State private var newItemName = ""
    @State private var newItemPrice = ""
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach($viewModel.items) { $item in
                        ItemRow(item: $item)
                    }
                    .onDelete(perform: viewModel.deleteItem)
                }
                
                HStack {
                    TextField("Nome do item", text: $newItemName)
                    TextField("Preço", text: $newItemPrice)
                        .keyboardType(.decimalPad)
                    Button("Adicionar") {
                        if let price = Double(newItemPrice), !newItemName.isEmpty {
                            viewModel.addItem(name: newItemName, price: price)
                            newItemName = ""
                            newItemPrice = ""
                        }
                    }
                    .disabled(newItemName.isEmpty || newItemPrice.isEmpty)
                }
                .padding()
                
                Text("Total: R$ \(viewModel.totalPrice, specifier: "%.2f")")
                Text("Total selecionado: R$ \(viewModel.selectedItemsPrice, specifier: "%.2f")")
            }
            .navigationTitle("Lista de Compras")
        }
    }
}

struct ItemRow: View {
    @Binding var item: Item
    
    var body: some View {
        HStack {
            TextField("Nome do item", text: $item.name)
            Spacer()
            TextField("Preço", value: $item.price, format: .currency(code: "BRL"))
                .keyboardType(.decimalPad)
            Toggle("", isOn: $item.isSelected)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

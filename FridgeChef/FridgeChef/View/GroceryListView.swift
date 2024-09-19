//
//  GroceryListView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

import SwiftUI

// 購物清單項目的數據結構

struct GroceryListView: View {
    let suggestedItems: [GroceryItem] = [
        GroceryItem(name: "Egg", isSuggested: true)
    ]
    
    let customItems: [GroceryItem] = [
        GroceryItem(name: "Apple", isSuggested: false),
        GroceryItem(name: "Onion", isSuggested: false),
        GroceryItem(name: "Potato", isSuggested: false)
    ]
    
    @State private var showingAddGroceryFormView = false // 控制 NewRestaurantView 的顯示

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Suggested Grocery List")) {
                    ForEach(suggestedItems) { item in
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.orange)
                            Text(item.name)
                        }
                    }
                }
                
                Section(header: Text("Custom Grocery List")) {
                    ForEach(customItems) { item in
                        HStack {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.orange)
                            Text(item.name)
                        }
                    }
                }
            }
            .navigationTitle("Grocery List")
            .navigationBarItems(trailing: Button(action: {
                showingAddGroceryFormView = true
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.orange)
            })
            .listStyle(GroupedListStyle())
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $showingAddGroceryFormView) {
                AddGroceryForm(viewModel: AddGroceryFormViewModel())

            }
        }
    }
}

struct GroceryListView_Previews: PreviewProvider {
    static var previews: some View {
        GroceryListView()
    }
}

//
//  FridgeView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/19.
//

import SwiftUI

struct FoodItem: Identifiable {
    var id = UUID()
    var name: String
    var quantity: Int
    var status: String
    var daysRemaining: Int
}

struct FridgeView: View {
    @State private var searchText = ""
    @State private var isEditing = false // 控制刪除模式的狀態
    @State private var showingMLIngredientView = false
    
    // 模擬的食材數據
    @State var foodItems: [FoodItem] = [
        FoodItem(name: "Apple", quantity: 2, status: "Closed", daysRemaining: 1),
        FoodItem(name: "Guacamole", quantity: 1, status: "Closed", daysRemaining: -8),
        FoodItem(name: "Apple", quantity: 2, status: "Closed", daysRemaining: 1),
        FoodItem(name: "Guacamole", quantity: 1, status: "Closed", daysRemaining: -8),
        FoodItem(name: "Apple", quantity: 2, status: "Closed", daysRemaining: 1),
        FoodItem(name: "Guacamole", quantity: 1, status: "Closed", daysRemaining: -8),
        FoodItem(name: "Apple", quantity: 2, status: "Closed", daysRemaining: 1),
        FoodItem(name: "Guacamole", quantity: 1, status: "Closed", daysRemaining: -8),
        FoodItem(name: "Apple", quantity: 2, status: "Closed", daysRemaining: 1),
        FoodItem(name: "Guacamole", quantity: 1, status: "Closed", daysRemaining: -8)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // 搜索框設計
                HStack {
                    TextField("Search food ingredient", text: $searchText)
                        .padding(7)
                        .padding(.horizontal, 25)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 8)
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        self.searchText = ""
                                    }) {
                                        Image(systemName: "multiply.circle.fill")
                                            .foregroundColor(.gray)
                                            .padding(.trailing, 8)
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, 10)
                    
                    if isEditing {
                        Button("Done") {
                            isEditing = false
                        }
                        .padding(.trailing, 10)
                        .transition(.slide)
                        .animation(.default)
                    }
                }
                .padding()
                
                List {
                    ForEach(foodItems.filter { $0.name.lowercased().contains(searchText.lowercased()) || searchText.isEmpty }) { item in
                        HStack {
                            if isEditing {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                                    .onTapGesture {
                                        self.foodItems.removeAll { $0.id == item.id }
                                    }
                            }
                            
                            Image(systemName: "photo")
                            VStack(alignment: .leading) {
                                Text("\(item.name)")
                                Text("\(item.quantity) - \(item.status)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(item.daysRemaining >= 0 ? "\(item.daysRemaining) days left" : "\(abs(item.daysRemaining)) days behind")
                                .foregroundColor(item.daysRemaining >= 0 ? .green : .red)
                        }
                    }
                }
                
                // 刪除按鈕
                Button("Delete") {
                    isEditing.toggle()
                }
                .padding()
                .accentColor(.red)
            }
            .navigationBarTitle("Storage", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                showingMLIngredientView = true
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.orange)
            })
            .sheet(isPresented: $showingMLIngredientView) {
                MLIngredientView()
            }
        }
    }
}

struct FridgeView_Previews: PreviewProvider {
    static var previews: some View {
        FridgeView()
    }
}

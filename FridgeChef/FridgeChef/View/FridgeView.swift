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

    // 模擬的食材數據
    @State var foodItems: [FoodItem] = [
        FoodItem(name: "Apple", quantity: 2, status: "Closed", daysRemaining: 1),
        FoodItem(name: "Guacamole", quantity: 1, status: "Closed", daysRemaining: -8)
    ]

    var body: some View {
        NavigationView {
            List {
                TextField("Search food ingredient", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                ForEach(foodItems.filter { $0.name.lowercased().contains(searchText.lowercased()) || searchText.isEmpty }) { item in
                    HStack {
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
            .navigationTitle("Storage")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addFoodItem) {
                        Image(systemName: "plus")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    // 添加食材的功能（暫時留空）
    func addFoodItem() {
        // 此處可添加新增食材的功能
    }
}

struct FridgeView_Previews: PreviewProvider {
    static var previews: some View {
        FridgeView()
    }
}


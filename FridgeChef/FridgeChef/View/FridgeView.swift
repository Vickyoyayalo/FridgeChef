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
    var image: UIImage?
}

struct FridgeView: View {
    @State private var searchText = ""
    @State private var isEditing = false // 控制刪除模式的狀態
    @State private var showingMLIngredientView = false
    @State private var editingItem: FoodItem?
    // 模擬的食材數據
    @State var foodItems: [FoodItem] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // 搜索框設計
                HStack {
                    if isEditing {
                        Button("Done") {
                            isEditing = false
                        }
                        .padding(.trailing, 10)
                        .transition(.slide)
                    }
                }
                List {
                    ForEach(foodItems.filter { $0.name.lowercased().contains(searchText.lowercased()) || searchText.isEmpty }) { item in
                        HStack {
                            if let image = item.image {
                                Image(uiImage: image)  // 显示从 MLIngredientView 传递过来的图片
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(10)
                            } else {
                                Image("newphoto")  // 显示默认图片
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(10)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("\(item.name)")
                                Text("\(item.quantity) - \(item.status)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(item.daysRemainingText)
                                .foregroundColor(item.daysRemainingColor)
                                .fontWeight(item.daysRemainingFontWeight)
                        }
                        .contentShape(Rectangle())  // 讓整個區域可點擊
                        .onTapGesture {
                            // 當點擊某個項目時，打開編輯視圖
                            editingItem = item
                            showingMLIngredientView = true
                        }
                    }
                    .onDelete(perform: deleteItems) // 添加删除功能
                }
                
                // 刪除按鈕
                Button("Delete") {
                    isEditing.toggle()
                }
                .padding()
                .accentColor(.red)
                .font(.headline)
            }
            .sheet(isPresented: $showingMLIngredientView) {
                if let editingItem = editingItem {
                    MLIngredientView(onSave: { updatedIngredient in
                        if let index = foodItems.firstIndex(where: { $0.id == editingItem.id }) {
                            let today = Calendar.current.startOfDay(for: Date())
                            let expirationDate = Calendar.current.startOfDay(for: updatedIngredient.expirationDate)
                            foodItems[index].name = updatedIngredient.name
                            foodItems[index].quantity = Int(updatedIngredient.quantity) ?? 1
                            foodItems[index].status = updatedIngredient.storageMethod
                            foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
                            foodItems[index].image = updatedIngredient.image
                        }
                    }, editingFoodItem: Ingredient(
                        name: editingItem.name,
                        quantity: "\(editingItem.quantity)",
                        expirationDate: Date().addingTimeInterval(Double(editingItem.daysRemaining * 24 * 60 * 60)),
                        storageMethod: editingItem.status,
                        image: editingItem.image
                    ))
                } else {
                    // 新增模式
                    MLIngredientView(onSave: { newIngredient in
                        let today = Calendar.current.startOfDay(for: Date())
                        let expirationDate = Calendar.current.startOfDay(for: newIngredient.expirationDate)
                        let newFoodItem = FoodItem(
                            name: newIngredient.name,
                            quantity: Int(newIngredient.quantity) ?? 1,
                            status: newIngredient.storageMethod,
                            daysRemaining: Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0,
                            image: newIngredient.image
                        )
                        foodItems.insert(newFoodItem, at: 0)
                    })
                }
            }
            .listStyle(PlainListStyle()) // 使用纯样式列表以减少间隙
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search food ingredient")
            .navigationBarTitle("Storage", displayMode: .automatic)
            .navigationBarItems(leading: EditButton(), trailing: addButton)
            .sheet(isPresented: $showingMLIngredientView) {
                MLIngredientView()
            }
        }
    }
    var addButton: some View {
        Button(action: { showingMLIngredientView = true }) {
            Image(systemName: "plus").foregroundColor(.orange)
        }
    }
    
    func deleteItems(at offsets: IndexSet) {
        foodItems.remove(atOffsets: offsets)
    }
    
}

extension FoodItem {
    var daysRemainingText: String {
        if daysRemaining > 2 {
            return "还可以放\(daysRemaining) 天"
        } else if daysRemaining >= 0 {
            return "再\(abs(daysRemaining))天过期👀"
        } else {
            return "过期\(abs(daysRemaining)) 天‼️"
        }
    }
    
    var daysRemainingColor: Color {
        if daysRemaining > 2 {
            return .gray  // 大于 2 天为黑色
        } else if daysRemaining >= 0 {
            return .green  // 小于等于 2 天为绿色
        } else {
            return .red    // 已过期为红色
        }
    }

    var daysRemainingFontWeight: Font.Weight {
        return daysRemaining < 0 ? .bold : .regular
    }
}

struct FridgeView_Previews: PreviewProvider {
    static var previews: some View {
        FridgeView()
    }
}


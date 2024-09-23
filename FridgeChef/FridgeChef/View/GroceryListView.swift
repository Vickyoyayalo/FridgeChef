//
//  GroceryListView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

import SwiftUI

struct GroceryListView: View {
    @State private var searchText = ""
    @State private var showingMLIngredientView = false
    @State private var editingItem: FoodItem?
    @State var foodItems: [FoodItem] = []
    @State private var showingMapView = false
    @State private var showingFridgeView = false
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                List {
                    ForEach(foodItems.filter { $0.name.lowercased().contains(searchText.lowercased()) || searchText.isEmpty }) { item in
                        HStack {
                            itemImageView(item: item)
                            
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
                .sheet(isPresented: $showingMLIngredientView) {
                    if let editingItem = editingItem {
                        // 编辑模式
                        MLIngredientView(onSave: { updatedIngredient in
                            handleSave(updatedIngredient)
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
                            handleSave(newIngredient)
                        })
                    }
                }
                VStack {
                    Button(action: {
                        showingMapView = true // 触发地图视图
                    }) {
                        VStack {
                            Text("附近超市")
                            Image(systemName: "location.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .padding(15)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                    }
                    .padding(.trailing, 15)
                    .padding(.bottom, 15)
                    .sheet(isPresented: $showingMapView) {
                        MapViewWithUserLocation(locationManager: LocationManager(), isPresented: $showingMapView)
                        
                    }
                }
            }
            .listStyle(PlainListStyle()) // 使用纯样式列表以减少间隙
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search food ingredient")
            .navigationBarTitle("Grocery", displayMode: .automatic)
            .navigationBarItems(leading: EditButton(), trailing: addButton)
            .sheet(isPresented: $showingMLIngredientView) {
                MLIngredientView()
            }
        }
    }
    
    var addButton: some View {
        Button(action: {
            // 点击添加按钮时设置为新增模式
            editingItem = nil
            showingMLIngredientView = true
        }) {
            Image(systemName: "plus").foregroundColor(.orange)
        }
    }
    
    func deleteItems(at offsets: IndexSet) {
        foodItems.remove(atOffsets: offsets)
    }
    
    func handleSave(_ ingredient: Ingredient) {
        if let editing = editingItem, let index = foodItems.firstIndex(where: { $0.id == editing.id }) {
            // 更新操作
            let today = Calendar.current.startOfDay(for: Date())
            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
            foodItems[index].name = ingredient.name
            foodItems[index].quantity = Int(ingredient.quantity) ?? 1
            foodItems[index].status = ingredient.storageMethod
            foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
            foodItems[index].image = ingredient.image
        } else {
            // 新增操作
            let today = Calendar.current.startOfDay(for: Date())
            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
            let newFoodItem = FoodItem(
                name: ingredient.name,
                quantity: Int(ingredient.quantity) ?? 1,
                status: ingredient.storageMethod,
                daysRemaining: Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0,
                image: ingredient.image
            )
            foodItems.insert(newFoodItem, at: 0)
        }
        // 重置 editingItem
        editingItem = nil
    }

    private func itemImageView(item: FoodItem) -> some View {
        if let image = item.image {
            return Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .cornerRadius(10)
        } else {
            return Image("newphoto")  // 显示默认图片
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .cornerRadius(10)
        }
    }
}

struct GroceryListView_Previews: PreviewProvider {
    static var previews: some View {
        GroceryListView()
    }
}

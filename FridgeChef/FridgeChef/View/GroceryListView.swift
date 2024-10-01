//
//  GroceryListView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject var foodItemStore: FoodItemStore
    @State private var searchText = ""
    @State private var showingMLIngredientView = false
    @State private var editingItem: FoodItem?
    @State var foodItems: [FoodItem] = []
    @State private var showingMapView = false
    @State private var showingFridgeView = false
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                // 漸層背景
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                ZStack(alignment: .bottomTrailing) {
                    List {
                        ForEach(foodItemStore.foodItems.filter { $0.name.lowercased().contains(searchText.lowercased()) || searchText.isEmpty }) { item in
                            HStack {
                                itemImageView(item: item)
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(item.name)
                                        .font(.headline)
                                    HStack {
                                        Text("數量：\(item.quantity) \(item.unit)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("狀態：\(item.status)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                                Text(item.daysRemainingText)
                                    .foregroundColor(item.daysRemainingColor)
                                    .fontWeight(item.daysRemainingFontWeight)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
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
                            // 假设默认量和单位
                            let defaultAmount = 1.0
                            let defaultUnit = "個"
                            
                            // 转换UIImage为Base64字符串
                            let base64Image = editingItem.image?.pngData()?.base64EncodedString()
                            
                            let ingredient = Ingredient(
                                name: editingItem.name,
                                quantity: "\(editingItem.quantity)",
                                amount: defaultAmount,
                                unit: defaultUnit,
                                expirationDate: Date().addingTimeInterval(Double(editingItem.daysRemaining * 24 * 60 * 60)),
                                storageMethod: editingItem.status,
                                imageBase64: base64Image
                            )
                            
                            MLIngredientView(onSave: { updatedIngredient in
                                handleSave(updatedIngredient)
                            }, editingFoodItem: ingredient)
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
                                Text("Nearby")
                                    .fontWeight(.bold)
                                    .shadow(radius: 10)
                                Image(systemName: "location.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .padding(15)
                                    .background(Color.white.opacity(0.7))
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
                .navigationBarTitle("Grocery 🛒 ", displayMode: .automatic)
                .navigationBarItems(leading: EditButton().bold(), trailing: addButton)
                .sheet(isPresented: $showingMLIngredientView) {
                    MLIngredientView()
                }
            }
        }
    }
    
    var addButton: some View {
        Button(action: {
            // 点击添加按钮时设置为新增模式
            editingItem = nil
            showingMLIngredientView = true
        }) {
            Image(systemName: "plus").foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                .bold()
        }
    }
    
    func deleteItems(at offsets: IndexSet) {
        foodItemStore.foodItems.remove(atOffsets: offsets)
    }
    
    func handleSave(_ ingredient: Ingredient) {
        if let editing = editingItem, let index = foodItemStore.foodItems.firstIndex(where: { $0.id == editing.id }) {
            // 更新现有项
            let today = Calendar.current.startOfDay(for: Date())
            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
            
            foodItemStore.foodItems[index].name = ingredient.name
            foodItemStore.foodItems[index].quantity = Int(ingredient.quantity) ?? 1
            foodItemStore.foodItems[index].status = ingredient.storageMethod
            foodItemStore.foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
            foodItemStore.foodItems[index].image = ingredient.image
        } else {
            // 添加新项
            let today = Calendar.current.startOfDay(for: Date())
            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
            let newFoodItem = FoodItem(
                name: ingredient.name,
                quantity: Int(ingredient.quantity ?? "") ?? 1,
                unit: ingredient.unit,
                status: ingredient.storageMethod,
                daysRemaining: Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0,
                image: ingredient.image
            )
            
            foodItemStore.foodItems.insert(newFoodItem, at: 0)
        }
        
        // 重置 editingItem
        editingItem = nil
    }

    private func itemImageView(item: FoodItem) -> some View {
        if let image = item.image {
            return Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .cornerRadius(20)
        } else {
            return Image("RecipeFood") 
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .cornerRadius(20)
        }
    }
}

struct GroceryListView_Previews: PreviewProvider {
    static var previews: some View {
        GroceryListView()
    }
}

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
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                ZStack(alignment: .bottomTrailing) {
                    List {
                        ForEach(foodItemStore.foodItems) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.headline)
                                    Text("\(item.quantity) \(item.unit)")
                                        .font(.subheadline)
                                    Text(item.daysRemainingText)
                                        .font(.caption)
                                        .foregroundColor(item.daysRemainingColor)
                                        .fontWeight(item.daysRemainingFontWeight)
                                }
                                Spacer()
                                // 添加操作按鈕，例如將食材移動到 FridgeView
                                Button(action: {
                                    moveToFridge(item: item)
                                }) {
                                    Image(systemName: "refrigerator.fill")
                                        .foregroundColor(.orange)
                                }
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
//                                Text("Nearby")
//                                    .fontWeight(.bold)
//                                    .shadow(radius: 10)
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
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search grocery items")
                .navigationBarTitle("Grocery 🛒 ", displayMode: .automatic)
                .navigationBarItems(leading: EditButton().bold(), trailing: addButton)
                .sheet(isPresented: $showingMLIngredientView) {
                    MLIngredientView()
                }
            }
        }
    }
    
    private func moveToFridge(item: FoodItem) {
        // 找到食材在 foodItemStore 中的索引
        if let index = foodItemStore.foodItems.firstIndex(where: { $0.id == item.id }) {
            // 更新狀態和 daysRemaining
            foodItemStore.foodItems[index].status = "Fridge"
            // 設置新的過期日期，例如 14 天後
            let newExpirationDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 0
            foodItemStore.foodItems[index].daysRemaining = daysRemaining
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

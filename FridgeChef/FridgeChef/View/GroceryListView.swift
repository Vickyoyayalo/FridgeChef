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
                            // 假设默认量和单位
                            let defaultAmount = 1.0  // 示例默认值
                            let defaultUnit = "個"  // 示例默认单位
                            
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
                                Text("附近超市")
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
                .navigationBarItems(leading: EditButton(), trailing: addButton)
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
            Image(systemName: "plus").foregroundColor(.orange)
        }
    }
    
    func deleteItems(at offsets: IndexSet) {
        foodItems.remove(atOffsets: offsets)
    }
    
    func handleSave(_ ingredient: Ingredient) {
        if let editing = editingItem, let index = foodItems.firstIndex(where: { $0.id == editing.id }) {
            // If editing existing item
            let today = Calendar.current.startOfDay(for: Date())
            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
            
            foodItems[index].name = ingredient.name
            foodItems[index].quantity = Int(ingredient.quantity ?? "") ?? 1
            foodItems[index].status = ingredient.storageMethod
            foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
            foodItems[index].image = ingredient.image
        } else {
            // If adding a new item
            let today = Calendar.current.startOfDay(for: Date())
            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
            let newFoodItem = FoodItem(
                name: ingredient.name,
                quantity: Int(ingredient.quantity ?? "") ?? 1,
                unit: ingredient.unit, status: ingredient.storageMethod,
                daysRemaining: Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0,
                image: ingredient.image
            )
            
            foodItems.insert(newFoodItem, at: 0)
        }
        
        // Reset editingItem
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
            return Image("newphoto")  // 显示默认图片
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

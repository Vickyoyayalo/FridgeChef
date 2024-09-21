//
//  GroceryListView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

//MARK: GOOD withoutgoogleAPI
import SwiftUI

struct GroceryListView: View {
    @State private var searchText = ""
    @State private var showingMLIngredientView = false
    @State private var editingItem: FoodItem?
    @State var foodItems: [FoodItem] = []
    // 新增：控制地图视图的展示
       @State private var showingMapView = false
       @StateObject private var locationManager = LocationManager() // 实例化 LocationManager

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(foodItems.filter { $0.name.lowercased().contains(searchText.lowercased()) || searchText.isEmpty }) { item in
                        HStack {
                            if let image = item.image {
                                Image(uiImage: image)
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
                // 定位图标按钮
                HStack {
                    Spacer()
                    Button(action: {
                        showingMapView = true
                    }) {
                        Image(systemName: "location.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .padding()
                    }
                    .sheet(isPresented: $showingMapView) {
                        MapViewWithUserLocation(locationManager: locationManager, isPresented: $showingMapView)
                    }
                }
                .padding()
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
            .navigationBarTitle("Grocery", displayMode: .automatic)
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

struct GroceryListView_Previews: PreviewProvider {
    static var previews: some View {
        GroceryListView()
    }
}

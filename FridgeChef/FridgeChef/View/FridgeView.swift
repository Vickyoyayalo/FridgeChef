//
//  FridgeView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/19.
//
//MARK:GOOD
import SwiftUI

struct FridgeView: View {
    @State private var searchText = ""
    @State private var isEditing = false // 控制刪除模式的狀態
    @State private var showingMLIngredientView = false
    @State private var editingItem: FoodItem?
    @State var foodItems: [FoodItem] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                VStack {
                    List {
                        ForEach(foodItems.filter { $0.name.lowercased().contains(searchText.lowercased()) || searchText.isEmpty }) { item in
                            HStack {
                                if let image = item.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(20)
                                } else {
                                    Image("RecipeFood")  // 显示默认图片
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(20)
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
                    .background(Color.clear)
                    .listStyle(PlainListStyle()) 
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
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search food ingredient")
                .navigationBarTitle("Storage 🥬 ", displayMode: .automatic)
                .navigationBarItems(leading: EditButton().bold(), trailing: addButton)
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
        foodItems.remove(atOffsets: offsets)
    }
    
    func handleSave(_ ingredient: Ingredient) {
        if let editing = editingItem, let index = foodItems.firstIndex(where: { $0.id == editing.id }) {
            // 更新操作
            let today = Calendar.current.startOfDay(for: Date())
            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
            foodItems[index].name = ingredient.name
            foodItems[index].quantity = Int(ingredient.quantity ?? "") ?? 1
            foodItems[index].status = ingredient.storageMethod
            foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
            foodItems[index].image = ingredient.image
        } else {
            // 新增操作
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
        // 重置 editingItem
        editingItem = nil
    }
}

struct FridgeView_Previews: PreviewProvider {
    static var previews: some View {
        FridgeView()
    }
}

////MARK:GOOD
//import SwiftUI
//
//struct FridgeView: View {
//    @State private var searchText = ""
//    @State private var isEditing = false // 控制刪除模式的狀態
//    @State private var showingMLIngredientView = false
//    @State private var editingItem: FoodItem?
//    @State var foodItems: [FoodItem] = []
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                List {
//                    ForEach(foodItems.filter { $0.name.lowercased().contains(searchText.lowercased()) || searchText.isEmpty }) { item in
//                        HStack {
//                            if let image = item.image {
//                                Image(uiImage: image)
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: 60, height: 60)
//                                    .cornerRadius(10)
//                            } else {
//                                Image("newphoto")  // 显示默认图片
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: 60, height: 60)
//                                    .cornerRadius(10)
//                            }
//
//                            VStack(alignment: .leading) {
//                                Text("\(item.name)")
//                                Text("\(item.quantity) - \(item.status)")
//                                    .font(.caption)
//                                    .foregroundColor(.gray)
//                            }
//                            Spacer()
//                            Text(item.daysRemainingText)
//                                .foregroundColor(item.daysRemainingColor)
//                                .fontWeight(item.daysRemainingFontWeight)
//                        }
//                        .contentShape(Rectangle())  // 讓整個區域可點擊
//                        .onTapGesture {
//                            // 當點擊某個項目時，打開編輯視圖
//                            editingItem = item
//                            showingMLIngredientView = true
//                        }
//                    }
//                    .onDelete(perform: deleteItems) // 添加删除功能
//                }
//            }
//            .sheet(isPresented: $showingMLIngredientView) {
//                if let editingItem = editingItem {
//                    MLIngredientView(onSave: { updatedIngredient in
//                        if let index = foodItems.firstIndex(where: { $0.id == editingItem.id }) {
//                            let today = Calendar.current.startOfDay(for: Date())
//                            let expirationDate = Calendar.current.startOfDay(for: updatedIngredient.expirationDate)
//                            foodItems[index].name = updatedIngredient.name
//                            foodItems[index].quantity = Int(updatedIngredient.quantity) ?? 1
//                            foodItems[index].status = updatedIngredient.storageMethod
//                            foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
//                            foodItems[index].image = updatedIngredient.image
//                        }
//                    }, editingFoodItem: Ingredient(
//                        name: editingItem.name,
//                        quantity: "\(editingItem.quantity)",
//                        expirationDate: Date().addingTimeInterval(Double(editingItem.daysRemaining * 24 * 60 * 60)),
//                        storageMethod: editingItem.status,
//                        image: editingItem.image
//                    ))
//                } else {
//                    // 新增模式
//                    MLIngredientView(onSave: { newIngredient in
//                        let today = Calendar.current.startOfDay(for: Date())
//                        let expirationDate = Calendar.current.startOfDay(for: newIngredient.expirationDate)
//                        let newFoodItem = FoodItem(
//                            name: newIngredient.name,
//                            quantity: Int(newIngredient.quantity) ?? 1,
//                            status: newIngredient.storageMethod,
//                            daysRemaining: Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0,
//                            image: newIngredient.image
//                        )
//                        foodItems.insert(newFoodItem, at: 0)
//                    })
//                }
//            }
//            .listStyle(PlainListStyle()) // 使用纯样式列表以减少间隙
//            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search food ingredient")
//            .navigationBarTitle("Storage", displayMode: .automatic)
//            .navigationBarItems(leading: EditButton(), trailing: addButton)
//            .sheet(isPresented: $showingMLIngredientView) {
//                MLIngredientView()
//            }
//        }
//    }
//    var addButton: some View {
//        Button(action: { showingMLIngredientView = true }) {
//            Image(systemName: "plus").foregroundColor(.orange)
//        }
//    }
//
//    func deleteItems(at offsets: IndexSet) {
//        foodItems.remove(atOffsets: offsets)
//    }
//
//}
//
//struct FridgeView_Previews: PreviewProvider {
//    static var previews: some View {
//        FridgeView()
//    }
//}

//MARK: MVVM架構可以修改的版本
//import SwiftUI
//
//struct FoodItem: Identifiable {
//    var id = UUID()
//    var name: String
//    var quantity: Int
//    var status: String
//    var daysRemaining: Int
//    var image: UIImage?
//}
//import SwiftUI
//
//struct FridgeView: View {
//    @State private var searchText = ""
//    @State private var showingMLIngredientView = false
//    @State private var editingItem: FoodItem?
//    @State var foodItems: [FoodItem] = []
//
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                List {
//                    ForEach(foodItems.filter { searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()) }) { item in
//                        HStack {
//                            itemImageView(for: item.image)
//
//                            VStack(alignment: .leading) {
//                                Text(item.name)
//                                Text("\(item.quantity) - \(item.status)")
//                                    .font(.caption)
//                                    .foregroundColor(.gray)
//                            }
//                            Spacer()
//                            Text(item.daysRemainingText)
//                                .foregroundColor(item.daysRemainingColor)
//                                .fontWeight(item.daysRemainingFontWeight)
//                        }
//                        .contentShape(Rectangle())
//                        .onTapGesture {
//                            editingItem = item
//                            showingMLIngredientView = true
//                        }
//                    }
//                    .onDelete(perform: deleteItems)
//                }
//            }
//            .searchable(text: $searchText, prompt: "Search food ingredient")
//            .navigationBarTitle("Storage")
//            .navigationBarItems(leading: EditButton(), trailing: addButton)
//        }
//        .sheet(isPresented: $showingMLIngredientView) {
//            // Ensure that the view model creation and view initialization are clear and unambiguous.
//            Group {
//                if let editingItem = editingItem {
//                    let viewModel = MLIngredientViewModel()
////                    viewModel.setup(with: Ingredient(from: editingItem))
//                    MLIngredientView(viewModel: viewModel)  // Make sure MLIngredientView accepts a viewModel and is a View
//                } else {
//                    MLIngredientView(viewModel: MLIngredientViewModel())  // Same as above
//                }
//            }
//            .transition(.slide) // Optional: Adding a transition for better UI experience
//            .animation(.default, value: showingMLIngredientView) // Optional: Adding animation
//        }
//
//    }
//
//    private func itemImageView(for image: UIImage?) -> some View {
//        Image(uiImage: image ?? UIImage(named: "newphoto")!)
//            .resizable()
//            .scaledToFit()
//            .frame(width: 60, height: 60)
//            .cornerRadius(10)
//    }
//
//    private func convertToIngredient(_ item: FoodItem) -> Ingredient {
//        Ingredient(
//            name: item.name,
//            quantity: "\(item.quantity)",
//            expirationDate: Date().addingTimeInterval(Double(item.daysRemaining * 86400)),
//            storageMethod: item.status,
//            image: item.image
//        )
//    }
//
//    private func updateItem(_ ingredient: Ingredient, for item: FoodItem) {
//        if let index = foodItems.firstIndex(where: { $0.id == item.id }) {
//            let today = Calendar.current.startOfDay(for: Date())
//            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
//            foodItems[index].name = ingredient.name
//            foodItems[index].quantity = Int(ingredient.quantity) ?? 1
//            foodItems[index].status = ingredient.storageMethod
//            foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
//            foodItems[index].image = ingredient.image
//        }
//    }
//
//    private func deleteItems(at offsets: IndexSet) {
//        foodItems.remove(atOffsets: offsets)
//    }
//
//    var addButton: some View {
//        Button(action: {
//            editingItem = nil  // This indicates a new item is being added
//            showingMLIngredientView = true
//        }) {
//            Image(systemName: "plus").foregroundColor(.orange)
//        }
//    }
//}
//
//extension FoodItem {
//    var daysRemainingText: String {
//        if daysRemaining > 2 {
//            return "還可以放\(daysRemaining) 天"
//        } else if daysRemaining >= 0 {
//            return "再\(abs(daysRemaining))天過期👀"
//        } else {
//            return "過期\(abs(daysRemaining)) 天‼️"
//        }
//    }
//    //TODO可以寫個今天到期的邏輯
//
//    var daysRemainingColor: Color {
//        if daysRemaining > 2 {
//            return .gray  // 大于 2 天为黑色
//        } else if daysRemaining >= 0 {
//            return .green  // 小于等于 2 天为绿色
//        } else {
//            return .red    // 已过期为红色
//        }
//    }
//
//    var daysRemainingFontWeight: Font.Weight {
//        return daysRemaining < 0 ? .bold : .regular
//    }
//}
//
//struct FridgeView_Previews: PreviewProvider {
//    static var previews: some View {
//        FridgeView()
//    }
//}

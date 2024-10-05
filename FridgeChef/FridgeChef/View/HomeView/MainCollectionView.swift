//
//  MainCollectionView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/30.
//

import SwiftUI
import FirebaseAuth

struct MainCollectionView: View {
    @EnvironmentObject var viewModel: RecipeSearchViewModel
    @EnvironmentObject var foodItemStore: FoodItemStore
    @State private var showingLogoutSheet = false
    @State private var showingNotificationSheet = false
    @State private var isEditing = false // 控制編輯模式狀態
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                gradientBackground
                    .blur(radius: showingLogoutSheet || showingNotificationSheet ? 5 : 0)
                
                recipeList
                    .navigationTitle("Bonjour, Vicky 🍻")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            menuButton
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            notificationButton
                        }
                    }
                    .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
            }
            .sheet(isPresented: $showingLogoutSheet) {
                LogoutSheetView()
                    .presentationDetents([.fraction(0.48)])
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showingNotificationSheet) {
                // Notification Sheet
                ZStack {
                    gradientBackground
                        .edgesIgnoringSafeArea(.all)
                    
                    notificationSheetContent
                }
                .presentationDetents([.fraction(0.48)])
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search in collection")
    }
    
    private var gradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.yellow, Color.orange]),
            startPoint: .top,
            endPoint: .bottom
        )
        .opacity(0.4)
        .edgesIgnoringSafeArea(.all)
    }
    
    private var recipeList: some View {
        List {
            ForEach(viewModel.recipes.filter { $0.isFavorite }) { recipe in
                RecipeRowView(recipe: recipe, toggleFavorite: {
                    viewModel.toggleFavorite(for: recipe.id)
                }, viewModel: RecipeSearchViewModel())
                .background(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
                .cornerRadius(10)
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteItems)
            .onMove(perform: moveItems)
        }
        .background(Color.clear)
        .listStyle(PlainListStyle()) // 確保列表沒有額外的內邊距或分隔線
    }
    
    private var menuButton: some View {
        Button(action: {
            showingLogoutSheet = true
        }) {
            Image(uiImage: UIImage(named: "settling") ?? UIImage(systemName: "gearshape.fill")!)
                .resizable()
                .frame(width: 24, height: 24) // 調整圖片大小
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
        }
    }
    
    private var notificationButton: some View {
        Button(action: {
            showingNotificationSheet = true
        }) {
            Image(uiImage: UIImage(named: "alarm") ?? UIImage(systemName: "bell.fill")!)
                .resizable()
                .frame(width: 24, height: 24) // 調整圖片大小
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
        }
    }
    
    private var notificationSheetContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Notification")
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                .font(.custom("ArialRoundedMTBold", size: 30))
                .padding(.top)
                .frame(maxWidth: .infinity)
            
            Divider()
                .background(Color.white)
                .padding(.horizontal)
            
            if expiringItemsCount > 0 {
                HStack {
                    Text("• ")
                        .foregroundColor(.primary)
                    Text("\(expiringItemsCount) items")
                        .foregroundColor(.blue)
                    Text(" expiring")
                        .foregroundColor(.primary)
                    Text(" within 3 days.")
                        .foregroundColor(.blue)
                }
                .fontWeight(.regular)
            }
            
            if expiredItemsCount > 0 {
                HStack {
                    Text("• ")
                        .foregroundColor(.primary)
                    Text("\(expiredItemsCount) items")
                        .foregroundColor(.red)
                    Text(" already")
                        .foregroundColor(.primary)
                    Text(" expired!")
                        .foregroundColor(.red)
                }
                .fontWeight(.bold)
            }
            Image("littlemonster")
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 200)
                .padding(.leading, 180)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.clear)
        )
    }
    
    private func logOut() {
        try? Auth.auth().signOut()
        UserDefaults.standard.set(false, forKey: "log_Status") // Ensure log_Status is updated appropriately
    }
    
    private func deleteAccount() {
        // 在此處添加 Firebase 或其他後端的帳戶刪除邏輯
        // 例如：
        // Auth.auth().currentUser?.delete { error in
        //     if let error = error {
        //         // 處理錯誤
        //     } else {
        //         // 刪除成功，更新 UI 或導航
        //     }
        // }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        withAnimation {
            viewModel.recipes.remove(atOffsets: offsets)
        }
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        withAnimation {
            viewModel.recipes.move(fromOffsets: source, toOffset: destination)
        }
    }
    
    private var expiringItemsCount: Int {
        foodItemStore.foodItems.filter { $0.daysRemaining <= 3 && $0.daysRemaining >= 0 }.count
    }
    
    private var expiredItemsCount: Int {
        foodItemStore.foodItems.filter { $0.daysRemaining < 0 }.count
    }
}

struct MainCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        MainCollectionView()
            .environmentObject(RecipeSearchViewModel())
            .environmentObject(FoodItemStore())
    }
}

//import SwiftUI
//import FirebaseAuth
//
//struct MainCollectionView: View {
//    @EnvironmentObject var viewModel: RecipeSearchViewModel
//    @EnvironmentObject var foodItemStore: FoodItemStore
//    @State private var showingLogoutSheet = false
//    @State private var showingNotificationSheet = false
//    @State private var isEditing = false // 控制编辑模式状态
//    @State private var searchText = ""
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                // 渐层背景
//                gradientBackground
//                    .blur(radius: showingLogoutSheet || showingNotificationSheet ? 20 : 0)
//                
//                recipeList
//                    .navigationTitle("Bonjour, Vicky 🍻")
//                    .toolbar {
//                        ToolbarItem(placement: .navigationBarLeading) {
//                            menuButton
//                        }
//                        
//                        ToolbarItem(placement: .navigationBarTrailing) {
//                            notificationButton
//                        }
//                    }
//                    .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
//            }
//            .sheet(isPresented: $showingLogoutSheet) {
//                // Log Out Sheet
//                ZStack {
//                    gradientBackground
//                        .edgesIgnoringSafeArea(.all)
//                    
//                    logoutSheetContent
//                }
//                .presentationDetents([.fraction(0.5)])
//            }
//            .sheet(isPresented: $showingNotificationSheet) {
//                // Notification Sheet
//                ZStack {
//                    gradientBackground
//                        .edgesIgnoringSafeArea(.all)
//                    
//                    notificationSheetContent
//                }
//                .presentationDetents([.fraction(0.5)])
//            }
//        }
//        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search in collection")
//    }
//    
//    private var gradientBackground: some View {
//        LinearGradient(
//            gradient: Gradient(colors: [Color.yellow, Color.orange]),
//            startPoint: .top,
//            endPoint: .bottom
//        )
//        .opacity(0.4)
//        .edgesIgnoringSafeArea(.all)
//    }
//    
//    private var recipeList: some View {
//        List {
//            ForEach(viewModel.recipes.filter { $0.isFavorite }) { recipe in
//                RecipeRowView(recipe: recipe, toggleFavorite: {
//                    viewModel.toggleFavorite(for: recipe.id)
//                }, viewModel: RecipeSearchViewModel())
//                .background(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
//                .cornerRadius(10)
//                .padding(.vertical, 4)
//                .listRowBackground(Color.clear)
//                .listRowSeparator(.hidden)
//            }
//            .onDelete(perform: deleteItems)
//            .onMove(perform: moveItems)
//        }
//        .background(Color.clear)
//        .listStyle(PlainListStyle()) // Ensure list has no extra padding or separators
//    }
//    
//    private var menuButton: some View {
//        Button(action: {
//            showingLogoutSheet = true
//        }) {
//            Image(uiImage: UIImage(named: "settling") ?? UIImage(systemName: "gearshape.fill")!)
//                .resizable()
//                .frame(width: 24, height: 24) // 調整圖片大小
//                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//        }
//    }
//    
//    private var notificationButton: some View {
//        Button(action: {
//            showingNotificationSheet = true
//        }) {
//            Image(uiImage: UIImage(named: "alarm") ?? UIImage(systemName: "bell.fill")!)
//                .resizable()
//                .frame(width: 24, height: 24) // 調整圖片大小
//                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//        }
//    }
//    
//    private var logoutSheetContent: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            HStack {
//                Image(systemName: "person.crop.circle")
//                    .resizable()
//                    .frame(width: 50, height: 50)
//                    .foregroundColor(.white)
//                
//                Text("Sign in")
//                    .font(.title2)
//                    .bold()
//                    .foregroundColor(.white)
//            }
//            .padding(.top, 40)
////            Text("Account Options")
////                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
////                .font(.custom("ArialRoundedMTBold", size: 20))
////                .padding(.top)
////            
//            Divider()
//                .background(Color.orange)
//                .padding(.horizontal)
//            
//            Button(action: {
//                logOut()
//            }) {
//                HStack {
//                    Image(systemName: "power.circle.fill")
//                        .foregroundColor(.white)
//                        .font(.title)
//                    Text("Log Out")
//                        .foregroundColor(.white)
//                        .font(.title3)
//                        .bold()
//                }
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(Color.red.opacity(0.7))
//                .cornerRadius(10)
//                .padding(.horizontal)
//            }
//
//            Button(action: {
//                // Handle account deletion
//                deleteAccount()
//            }) {
//                HStack {
//                    Image(systemName: "trash.fill")
//                        .foregroundColor(.white)
//                        .font(.title)
//                    Text("Delete Account")
//                        .foregroundColor(.white)
//                        .font(.title3)
//                        .bold()
//                }
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(Color.gray.opacity(0.7))
//                .cornerRadius(10)
//                .padding(.horizontal)
//            }
//            
////            Button(action: {
////                showingLogoutSheet = false
////            }) {
////                Text("Cancel")
////                    .foregroundColor(.white)
////                    .padding()
////                    .frame(maxWidth: .infinity)
////                    .background(Color.blue.opacity(0.7))
////                    .cornerRadius(10)
////                    .padding(.horizontal)
////            }
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color.clear)
//        )
//    }
//    
//    private var notificationSheetContent: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            Text("Notification")
//                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                .font(.custom("ArialRoundedMTBold", size: 20))
//                .padding(.top)
//                .frame(maxWidth: .infinity)
//            
//            Divider()
//                .background(Color.white)
//                .padding(.horizontal)
//            
//            if expiringItemsCount > 0 {
//                        HStack {
//                            Text("You have ")
//                                .foregroundColor(.primary)
//                            Text("\(expiringItemsCount) items")
//                                .foregroundColor(.blue)
//                            Text("expiring")
//                                .foregroundColor(.primary)
//                            Text("within 3 days.")
//                                .foregroundColor(.blue)
//                        }
//                        .fontWeight(.regular)
//                    }
//                    
//                    if expiredItemsCount > 0 {
//                        HStack {
//                            Text("You have ")
//                                .foregroundColor(.primary)
//                            Text("\(expiredItemsCount)")
//                                .foregroundColor(.red)
//                            Text(" items already")
//                                .foregroundColor(.primary)
//                            Text(" expired!")
//                                .foregroundColor(.red)
//                        }
//                        .fontWeight(.bold)
//                    }
//            Spacer()
////            Button("OK", role: .cancel) {
////                showingNotificationSheet = false
////            }
////            .padding()
////            .frame(maxWidth: .infinity)
////            .background(Color.blue.opacity(0.7))
////            .cornerRadius(10)
////            .foregroundColor(.white)
////            .padding(.horizontal)
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color.clear)
//        )
//    }
//    
//    private func logOut() {
//        try? Auth.auth().signOut()
//        UserDefaults.standard.set(false, forKey: "log_Status") // Ensure log_Status is updated appropriately
//    }
//    
//    private func deleteAccount() {
//        // 在此處添加 Firebase 或其他後端的帳戶刪除邏輯
//        // 例如：
//        // Auth.auth().currentUser?.delete { error in
//        //     if let error = error {
//        //         // 處理錯誤
//        //     } else {
//        //         // 刪除成功，更新 UI 或導航
//        //     }
//        // }
//    }
//    
//    private func deleteItems(at offsets: IndexSet) {
//        withAnimation {
//            viewModel.recipes.remove(atOffsets: offsets)
//        }
//    }
//    
//    private func moveItems(from source: IndexSet, to destination: Int) {
//        withAnimation {
//            viewModel.recipes.move(fromOffsets: source, toOffset: destination)
//        }
//    }
//    
//    private var expiringItemsCount: Int {
//        foodItemStore.foodItems.filter { $0.daysRemaining <= 3 && $0.daysRemaining >= 0 }.count
//    }
//    
//    private var expiredItemsCount: Int {
//        foodItemStore.foodItems.filter { $0.daysRemaining < 0 }.count
//    }
//}
//
//struct MainCollectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainCollectionView()
//            .environmentObject(RecipeSearchViewModel())
//            .environmentObject(FoodItemStore())
//    }
//}
//

//MARK: -GOOD
//import SwiftUI
//import FirebaseAuth
//
//struct MainCollectionView: View {
//    @EnvironmentObject var viewModel: RecipeSearchViewModel
//    @State private var showingLogoutConfirmation = false
//    @State private var isEditing = false // 控制编辑模式状态
//    @State private var searchText = ""
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                // 渐层背景
//                LinearGradient(
//                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .opacity(0.4)
//                .edgesIgnoringSafeArea(.all)
//                
//                List {
//                    ForEach(viewModel.recipes.filter { $0.isFavorite }) { recipe in
//                        RecipeRowView(recipe: recipe, toggleFavorite: {
//                            viewModel.toggleFavorite(for: recipe.id)
//                        }, viewModel: RecipeSearchViewModel())
//                        .background(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
//                        .cornerRadius(10)
//                        .padding(.vertical, 4)
//                        .listRowBackground(Color.clear)
//                        .listRowSeparator(.hidden)
//                    }
//                    .onDelete(perform: deleteItems)
//                    .onMove(perform: moveItems)
//                }
//                .background(Color.clear)
//                .listStyle(PlainListStyle()) // Ensure list has no extra padding or separators
//                .navigationTitle("Bonjour, Vicky 🍻")
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        logoutButton
//                    }
//                    ToolbarItem(placement: .navigationBarLeading) {
//                        editButton
//                    }
//                }
//                .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
//                .alert("Are you sure you want to log out?", isPresented: $showingLogoutConfirmation) {
//                    Button("Log Out", role: .destructive) {
//                        logOut()
//                    }
//                    Button("Cancel", role: .cancel) {}
//                }
//            }
//        }
//        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search in collection")
//        // 使用 searchText 来过滤你的内容
//        .alert("Are you sure you want to log out?", isPresented: $showingLogoutConfirmation) {
//            Button("Log Out", role: .destructive) {
//                logOut()
//            }
//            Button("Cancel", role: .cancel) {}
//        }
//    }
//    
//    private var logoutButton: some View {
//        Button(action: {
//            showingLogoutConfirmation = true
//        }) {
//            Image(systemName: "power.circle.fill")
//        }
//    }
//    
//    private var editButton: some View {
//        Button(action: {
//            isEditing.toggle()
//        }) {
//            Text(isEditing ? "Done" : "Edit")
//                .bold()
//        }
//    }
//    
//    private func logOut() {
//        try? Auth.auth().signOut()
//        UserDefaults.standard.set(false, forKey: "log_Status") // Ensure log_Status is updated appropriately
//    }
//    
//    private func deleteItems(at offsets: IndexSet) {
//        withAnimation {
//            viewModel.recipes.remove(atOffsets: offsets)
//        }
//    }
//    
//    private func moveItems(from source: IndexSet, to destination: Int) {
//        withAnimation {
//            viewModel.recipes.move(fromOffsets: source, toOffset: destination)
//        }
//    }
//}
//
//struct MainCollectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainCollectionView().environmentObject(RecipeSearchViewModel())
//    }
//}

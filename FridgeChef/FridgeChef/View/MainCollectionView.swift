//
//  MainCollectionView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/30.
//

import SwiftUI
import FirebaseAuth

//struct MainCollectionView: View {
//    // User Log Status
//    @AppStorage("log_Status") private var logStatus: Bool = false
//    @EnvironmentObject var viewModel: RecipeSearchViewModel
//    @State private var showingLogoutConfirmation = false
//    @State private var isEditing = false
//    @State private var searchText = ""  
//
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                // 漸層背景
//                LinearGradient(
//                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .opacity(0.3)
//                .edgesIgnoringSafeArea(.all)
//                
//                VStack {
//                    List(viewModel.recipes.filter { $0.isFavorite }) { recipe in
//                                   RecipeRowView(recipe: recipe, toggleFavorite: {
//                                       viewModel.toggleFavorite(for: recipe.id)
//                                   }, viewModel: viewModel)
//                    }
//                    .listStyle(PlainListStyle())
//                    Text("Your content goes here...")
//                        .foregroundColor(.gray)
//                        .padding()
//                    // 其他内容...
//                }
//                .navigationTitle("My Collection 🥘")
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        logoutButton
//                    }
//                    ToolbarItem(placement: .navigationBarLeading) {
//                        editButton
//                    }
//                }
//                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search in collection")
//                // 使用 searchText 来过滤你的内容
//                .alert("Are you sure you want to log out?", isPresented: $showingLogoutConfirmation) {
//                    Button("Log Out", role: .destructive) {
//                        logOut()
//                    }
//                    Button("Cancel", role: .cancel) {}
//                }
//            }
//        }
//    }
//
//    private var logoutButton: some View {
//        Button(action: {
//            showingLogoutConfirmation = true
//        }) {
//            Text("Bye🥹")
////            Image(systemName: "power.circle.fill")
//                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                .frame(width: 60, height: 10)
//                .fontWeight(.bold)
//                .padding(8)
//                .overlay(RoundedRectangle(cornerRadius: 8).stroke(
//                    Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange), lineWidth: 2))
////                .shadow(radius: 5)
//        }
//    }
//
//    private var editButton: some View {
//        Button(action: {
//            isEditing.toggle()  // 切换编辑模式
//        }) {
//            Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
//                .foregroundColor(isEditing ? .green : .orange)
//        }
//    }
//
//    private func logOut() {
//        try? Auth.auth().signOut()
//        logStatus = false
//    }
//}
//
//struct MainCollectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainCollectionView()
//    }
//}
import SwiftUI

struct MainCollectionView: View {
    @EnvironmentObject var viewModel: RecipeSearchViewModel
    @State private var showingLogoutConfirmation = false
    @State private var isEditing = false // 控制编辑模式状态
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // 渐层背景
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)

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
                .listStyle(PlainListStyle()) // Ensure list has no extra padding or separators
                .navigationTitle("My Collection 🥘")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        logoutButton
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        editButton
                    }
                }
                .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
                .alert("Are you sure you want to log out?", isPresented: $showingLogoutConfirmation) {
                    Button("Log Out", role: .destructive) {
                        logOut()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
    }

    private var logoutButton: some View {
        Button(action: {
            showingLogoutConfirmation = true
        }) {
            Image(systemName: "power.circle.fill")
        }
    }

    private var editButton: some View {
        Button(action: {
            isEditing.toggle()
        }) {
            Text(isEditing ? "Done" : "Edit")
                .bold()
        }
    }

    private func logOut() {
        try? Auth.auth().signOut()
        UserDefaults.standard.set(false, forKey: "log_Status") // Ensure log_Status is updated appropriately
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
}

struct MainCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        MainCollectionView().environmentObject(RecipeSearchViewModel())
    }
}

//
//  MainCollectionView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/30.
//

import SwiftUI
import FirebaseAuth

struct MainCollectionView: View {
    // User Log Status
    @AppStorage("log_Status") private var logStatus: Bool = false
    @State private var showingLogoutConfirmation = false
    @State private var isEditing = false // 控制编辑模式状态
    @State private var searchText = ""  // 添加用于搜索的状态变量

    var body: some View {
        NavigationStack {
            ZStack {
                // 漸層背景
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // 如果有内容数组，可以在这里使用 ForEach 来显示内容
                    Text("Your content goes here...")
                        .foregroundColor(.gray)
                        .padding()
                    // 其他内容...
                }
                .navigationTitle("My Collection 🥘")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        logoutButton
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        editButton
                    }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search in collection")
                // 使用 searchText 来过滤你的内容
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
            Text("Bye🥹")
//            Image(systemName: "power.circle.fill")
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                .frame(width: 60, height: 10)
                .fontWeight(.bold)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                    Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange), lineWidth: 2))
//                .shadow(radius: 5)
        }
    }

    private var editButton: some View {
        Button(action: {
            isEditing.toggle()  // 切换编辑模式
        }) {
            Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                .foregroundColor(isEditing ? .green : .orange)
        }
    }

    private func logOut() {
        try? Auth.auth().signOut()
        logStatus = false
    }
}

struct MainCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        MainCollectionView()
    }
}

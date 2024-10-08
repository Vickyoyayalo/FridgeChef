//
//  LogoutSheetView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/5.
//

import SwiftUI
import FirebaseAuth

struct LogoutSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var userName: String = "User"
    @State private var userImage: Image = Image(systemName: "person.crop.circle")
    
    var body: some View {
        VStack(spacing: 20) {
            // 用戶信息
            HStack {
                userImage
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 10)
                    .padding()
                Text(userName)
                    .font(.custom("ArialRoundedMTBold", size: 30))
                    .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
            }
            .padding(.top, 40)
            
            Divider()
                .background(Color.orange)
                .padding(.horizontal)
            
            // Log Out 按鈕
            Button(action: {
                showLogoutAlert = true
            }) {
                HStack {
                    Image(systemName: "power.circle.fill")
                        .foregroundColor(.white)
                        .font(.title)
                    Text("Log Out")
                        .foregroundColor(.white)
                        .font(.custom("ArialRoundedMTBold", size: 25))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.7))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .alert(isPresented: $showLogoutAlert) {
                Alert(
                    title: Text("Log Out"),
                    message: Text("Are you sure you want to log out?"),
                    primaryButton: .destructive(Text("Log Out")) {
                        logOut()
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
            
            // Delete Account 按鈕
            Button(action: {
                showDeleteAccountAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                        .font(.title)
                    Text("Delete Account")
                        .foregroundColor(.white)
                        .font(.custom("ArialRoundedMTBold", size: 25))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.7))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .alert(isPresented: $showDeleteAccountAlert) {
                Alert(
                    title: Text("Delete Account"),
                    message: Text("Are you sure you want to delete your account🥲? \nThis action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteAccount()
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
            
            // Cancel 按鈕
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom))
                .opacity(0.4)
        )
        .shadow(radius: 10)
        .onAppear {
            loadUserInfo()
        }
    }
    
    // 加載用戶信息
    private func loadUserInfo() {
        if let user = Auth.auth().currentUser {
            self.userName = user.displayName ?? "User"
            
            if let photoURL = user.photoURL {
                // 從 URL 加載圖片
                URLSession.shared.dataTask(with: photoURL) { data, response, error in
                    if let data = data, let uiImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.userImage = Image(uiImage: uiImage)
                        }
                    }
                }.resume()
            }
        }
    }
    
    // 登出函數
    private func logOut() {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.set(false, forKey: "log_Status")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    // 刪除帳戶函數
    private func deleteAccount() {
        Auth.auth().currentUser?.delete { error in
            if let error = error {
                print("Failed to delete account: \(error.localizedDescription)")
                // 可以在這裡顯示錯誤提示給用戶
            } else {
                print("Account successfully deleted")
                UserDefaults.standard.set(false, forKey: "log_Status")
                // 可以在這裡導航到登錄頁面或其他適當的操作
            }
        }
    }
}


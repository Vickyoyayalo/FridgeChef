//
//  LogoutSheetView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/5.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LogoutSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var userName: String = "User"
    @State private var userImage: Image = Image("himonster")
    
    var body: some View {
        ZStack {
            // 漸層背景
            LinearGradient(
                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.4)
            .edgesIgnoringSafeArea(.all)
            
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
                Spacer()
            }
            .padding()
        }
        //        .background(
        //            RoundedRectangle(cornerRadius: 20)
        //                .fill(LinearGradient(
        //                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
        //                    startPoint: .top,
        //                    endPoint: .bottom))
        //                .opacity(0.4)
        //        )
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
    
    // 先標記帳戶為已刪除，然後再刪除 Firebase Authentication 帳戶
    func deleteAccount() {
        if let user = Auth.auth().currentUser {
            let uid = user.uid
            
            // 1. 標記 Firestore 中的帳戶為已刪除
            let db = Firestore.firestore()
            db.collection("users").document(uid).updateData(["isDeleted": true]) { error in
                if let error = error {
                    print("Error marking account as deleted: \(error.localizedDescription)")
                } else {
                    // 2. 完成 Firestore 操作後再刪除 Firebase Authentication 中的帳戶
                    user.delete { error in
                        if let error = error {
                            print("Failed to delete account: \(error.localizedDescription)")
                        } else {
                            print("Account successfully deleted")
                            UserDefaults.standard.set(false, forKey: "log_Status")
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }



    // 標記帳戶為已刪除
    func markAccountAsDeleted(email: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else if let document = querySnapshot?.documents.first {
                let documentID = document.documentID
                db.collection("users").document(documentID).updateData(["isDeleted": true]) { error in
                    if let error = error {
                        print("Error marking account as deleted: \(error)")
                    } else {
                        print("Account marked as deleted.")
                        completion()
                    }
                }
            }
        }
    }
    
    // Email 註冊登入
    func registerWithEmail(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
            } else if let user = authResult?.user {
                let newUID = user.uid
                // 使用 email 查找舊數據並關聯新的 UID
                linkNewUIDToOldData(newUID: newUID, email: email)
            }
        }
    }

    // Sign In with Apple
    func signInWithApple(email: String) {
        // 當成功登入後，會獲得新的 UID
        if let user = Auth.auth().currentUser {
            let newUID = user.uid
            // 使用 email 查找舊數據並關聯新的 UID
            linkNewUIDToOldData(newUID: newUID, email: email)
        }
    }
    
    // 檢查帳戶是否已存在
    func checkIfEmailExists(email: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error checking email: \(error)")
                completion(false)
            } else {
                if let document = querySnapshot?.documents.first {
                    let isDeleted = document.get("isDeleted") as? Bool ?? false
                    if isDeleted {
                        completion(true) // 帳戶存在且已刪除
                    } else {
                        completion(false) // 帳戶存在且未刪除
                    }
                } else {
                    completion(false) // 帳戶不存在
                }
            }
        }
    }
    
    // 關聯新 UID 到舊數據
    func linkNewUIDToOldData(newUID: String, email: String) {
        let db = Firestore.firestore()
        
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else if let document = querySnapshot?.documents.first {
                let oldDocumentID = document.documentID
                let isDeleted = document.get("isDeleted") as? Bool ?? false
                
                if isDeleted {
                    // 將新的 UID 更新回舊數據，並取消刪除標記
                    db.collection("users").document(oldDocumentID).updateData(["uid": newUID, "isDeleted": false]) { error in
                        if let error = error {
                            print("Error updating UID: \(error)")
                        } else {
                            print("UID successfully updated, and account restored.")
                        }
                    }
                } else {
                    print("No deleted account found.")
                }
            }
        }
    }

    func markAccountAsDeleted() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        let db = Firestore.firestore()
        
        db.collection("users").whereField("email", isEqualTo: userEmail).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                if let document = querySnapshot?.documents.first {
                    let documentID = document.documentID
                    db.collection("users").document(documentID).updateData(["isDeleted": true]) { error in
                        if let error = error {
                            print("Error marking account as deleted: \(error)")
                        } else {
                            print("Account marked as deleted.")
                        }
                    }
                }
            }
        }
    }
}



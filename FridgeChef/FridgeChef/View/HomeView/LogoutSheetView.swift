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
    @State private var userName: String = "Hi~ Foodie 🍲"
    @State private var userImage: Image = Image("himonster")
    @State private var showLoginView = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.4)
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                HStack {
                    userImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                        .padding()
                        
                    Text(userName)
                        .font(.custom("ArialRoundedMTBold", size: 30))
                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                }
                .padding(.top, 40)
                
                Divider()
                
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
        
        .shadow(radius: 10)
        .onAppear {
            loadUserInfo()
        }
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView()
        }

    }
       
    func resetAppPermissions() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }

    private func loadUserInfo() {
        if let user = Auth.auth().currentUser {
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).getDocument { (document, error) in
                if let document = document, document.exists {
                    if let isDeleted = document.data()?["isDeleted"] as? Bool, isDeleted {
                        logOut()
                        showLoginView = true
                    } else {
                        if let storedUserName = document.data()?["userName"] as? String {
                            self.userName = storedUserName
                        } else {
                            self.userName = user.displayName ?? "Foodie"
                        }
                        if let photoURL = user.photoURL {
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
            }
        }
    }

    func saveUserNameToFirestore() {
        if let user = Auth.auth().currentUser {
            let db = Firestore.firestore()
            let displayName = user.displayName ?? "Foodie"
            
            db.collection("users").document(user.uid).setData([
                "userName": displayName
            ], merge: true) { error in
                if let error = error {
                    print("Error saving userName to Firestore: \(error)")
                } else {
                    print("UserName saved to Firestore.")
                }
            }
        }
    }
    
    private func logOut() {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.set(false, forKey: "log_Status")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    // 先標記帳戶為已刪除，然後再刪除 Firebase Authentication 帳戶
    private func deleteAccount() {
        if let user = Auth.auth().currentUser {
            let uid = user.uid
            let db = Firestore.firestore()
            
            // 標記帳號已删除
            db.collection("users").document(uid).updateData(["isDeleted": true]) { error in
                if let error = error {
                    print("Error marking account as deleted: \(error.localizedDescription)")
                } else {
                    // 2. 完成 Firestore 操作后删除 Firebase Authentication 帳戶
                    user.delete { error in
                        if let error = error {
                            print("Failed to delete account: \(error.localizedDescription)")
                        } else {
                            print("Account successfully deleted")
                            UserDefaults.standard.set(false, forKey: "log_Status")
                            showLoginView = true
                        }
                    }
                }
            }
        }
    }

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
    
    func registerWithEmail(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
            } else if let user = authResult?.user {
                let newUID = user.uid
                linkNewUIDToOldData(newUID: newUID, email: email)
            }
        }
    }

    func signInWithApple(email: String) {
       
        if let user = Auth.auth().currentUser {
            let newUID = user.uid
           
            linkNewUIDToOldData(newUID: newUID, email: email)
            saveUserNameToFirestore()
        }
    }
    
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
                        completion(true)
                    } else {
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }
    }
    
    func linkNewUIDToOldData(newUID: String, email: String) {
        let db = Firestore.firestore()
        
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else if let document = querySnapshot?.documents.first {
                let oldDocumentID = document.documentID
                let isDeleted = document.get("isDeleted") as? Bool ?? false
                
                if isDeleted {
                  
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


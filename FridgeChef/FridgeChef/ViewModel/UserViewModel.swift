//
//  UserViewModel.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import Firebase

class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var errorMessage: String?
    
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var avatar: UIImage? = nil
    
    private var firestoreService = FirestoreService()
    
    func signUpUser(completion: @escaping (Bool) -> Void) {
        // Implementation here
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage = "註冊失敗: \(error.localizedDescription)"
                return
            }
            
            guard let uid = result?.user.uid else {
                self.errorMessage = "無法獲取用戶ID"
                return
            }
            
            let userData = ["name": self.name, "email": self.email, "avatar": self.user?.avatar ?? ""]
            self.firestoreService.saveUser(userData, uid: uid) { result in
                switch result {
                case .success():
                    print("User data saved successfully")
                case .failure(let error):
                    self.errorMessage = "保存用户數據失敗: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func sendPasswordReset(email: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("Reset password error: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

}


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
    
    func signUpUser(name: String, email: String, password: String, avatar: UIImage?, completion: @escaping (Bool) -> Void) {
        // 使用 Firebase Authentication 來創建使用者
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = "註冊失敗: \(error.localizedDescription)"
                completion(false)
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            // 上傳大頭照 (如有)
            if let avatarImage = avatar, let imageData = avatarImage.jpegData(compressionQuality: 0.8) {
                let storageRef = Storage.storage().reference(withPath: "avatars/\(uid).jpg")
                storageRef.putData(imageData) { _, error in
                    if let error = error {
                        self.errorMessage = "大頭照上傳失敗: \(error.localizedDescription)"
                        completion(false)
                        return
                    }
                    
                    storageRef.downloadURL { url, error in
                        guard let downloadURL = url else {
                            self.errorMessage = "獲取照片URL失敗: \(error?.localizedDescription ?? "未知錯誤")"
                            completion(false)
                            return
                        }
                        
                        // 註冊成功，將使用者資料存入 Firestore
                        self.storeUserInformation(uid: uid, name: name, email: email, avatarURL: downloadURL.absoluteString, completion: completion)
                    }
                }
            } else {
                // 無大頭照直接儲存資料
                self.storeUserInformation(uid: uid, name: name, email: email, avatarURL: nil, completion: completion)
            }
        }
    }
    
    private func storeUserInformation(uid: String, name: String, email: String, avatarURL: String?, completion: @escaping (Bool) -> Void) {
        let userData = [
            "name": name,
            "email": email,
            "avatar": avatarURL ?? "",
            "ingredientId": "", // 初始為空，之後可以更新食材ID
            "password": ""
        ]
        
        Firestore.firestore().collection("users").document(uid).setData(userData) { error in
            if let error = error {
                self.errorMessage = "存儲資料失敗: \(error.localizedDescription)"
                completion(false)
                return
            }
            
            self.user = User(id: uid, avatar: avatarURL ?? "", name: name, email: email, password: "", category: [])
            completion(true)
        }
    }
}


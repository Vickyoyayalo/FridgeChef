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
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var alert: Alert = Alert(title: Text("Unknown Error"))

    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var avatar: UIImage? = nil

    private var alertService = AlertService()
    private var firestoreService = FirestoreService()

    func signUpUser() {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    self.alert = Alert(title: Text("註冊失敗"), message: Text(error.localizedDescription))
                    self.showAlert = true
                    return
                }

                guard let uid = result?.user.uid else {
                    self.alert = Alert(title: Text("註冊失敗"), message: Text("無法獲取用戶ID"))
                    self.showAlert = true
                    return
                }

                self.uploadAvatar(uid: uid) { success, url in
                    let userData = [
                        "name": self.name,
                        "email": self.email,
                        "avatar": url ?? ""
                    ]
                    self.firestoreService.saveUser(userData, uid: uid) { result in
                        switch result {
                        case .success():
                            self.alert = Alert(title: Text("註冊成功"), message: Text("註冊成功!"))
                        case .failure(let error):
                            self.alert = Alert(title: Text("註冊失敗"), message: Text("無法儲存大頭照: \(error.localizedDescription)"))
                        }
                        self.showAlert = true
                    }
                }
            }
        }
    }

    private func uploadAvatar(uid: String, completion: @escaping (Bool, String?) -> Void) {
        guard let avatar = avatar, let imageData = avatar.jpegData(compressionQuality: 0.8) else {
            completion(true, nil) // No avatar, proceed without uploading
            return
        }

        let storageRef = Storage.storage().reference().child("avatars/\(uid).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(false, nil)
                return
            }

            storageRef.downloadURL { url, error in
                if let downloadURL = url {
                    completion(true, downloadURL.absoluteString)
                } else {
                    completion(false, nil)
                }
            }
        }
    }
    
    func fetchUserDetails(uid: String) {
        firestoreService.fetchUser(byUid: uid) { user, error in
            DispatchQueue.main.async {
                if let user = user {
                    self.user = user
                    self.name = user.name
                    self.email = user.email
                    // Assume avatar is a URL
                    self.downloadImage(from: user.avatar)
                } else {
                    print("No user found or \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    func sendPasswordReset(email: String) {
            firestoreService.sendPasswordReset(email: email) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success():
                        self.alertTitle = "Password Reset"
                        self.alertMessage = "Reset link sent successfully."
                    case .failure(let error):
                        self.alertTitle = "Password Reset Error"
                        self.alertMessage = error.localizedDescription
                    }
                    self.showAlert = true
                }
            }
        }
    
    private func downloadImage(from urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.avatar = image
                }
            }
        }.resume()
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.name = ""
            self.email = ""
            self.avatar = nil
        } catch {
            self.alert = Alert(title: Text("登出失敗"), message: Text(error.localizedDescription))
            self.showAlert = true
        }
    }
}

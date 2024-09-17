//
//  LoginDetailViewModel.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/17.
//
import SwiftUI
import FirebaseAuth

class LoginDetailViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var uid: String?

    func login(completion: @escaping () -> Void) {
        guard !email.isEmpty, !password.isEmpty else {
            self.alertMessage = "請輸入電子郵件和密碼。"
            self.showAlert = true
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.alertMessage = error.localizedDescription
                    self?.showAlert = true
                } else {
                    completion()  // Execute completion handler on successful login
                }
            }
        }
    }
}

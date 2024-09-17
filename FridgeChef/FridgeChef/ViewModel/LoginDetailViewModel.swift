//
//  LoginDetailViewModel.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/17.
//

import Foundation
import FirebaseAuth

class LoginDetailViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String?
    
    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "請輸入電子郵件和密碼。"
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                // 如果登入失敗，顯示錯誤訊息
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            } else {
                // 登入成功，處理成功邏輯
                DispatchQueue.main.async {
                    self.errorMessage = nil
                    print("登入成功！")
                    // 例如跳轉至主頁面邏輯
                }
            }
        }
    }
}


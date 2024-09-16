//
//  SignUpView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel = UserViewModel() // 透過 ViewModel 處理用戶註冊
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var avatar: UIImage? = nil // 用戶大頭照

    var body: some View {
        VStack {
            // 顯示錯誤信息（如果有）
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }
            
            // 使用者輸入框
            TextField("姓名", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("密碼", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // 註冊按鈕
            Button(action: {
                // 使用 ViewModel 進行註冊操作
                viewModel.signUpUser(name: name, email: email, password: password, avatar: avatar) { success in
                    if success {
                        print("註冊成功！")
                    } else {
                        print("註冊失敗")
                    }
                }
            }) {
                Text("註冊")
            }
            .padding()
        }
        .padding()
    }
}

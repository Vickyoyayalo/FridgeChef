//
//  ForgotPasswordView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var showingAlert = false // 控制彈出提示框的狀態
    @State private var alertMessage = "" // 提示框的訊息
    @ObservedObject private var viewModel = UserViewModel() // 確保 ViewModel 初始化正確
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        CustomNavigationBarView(title: "") {
            
            VStack(spacing: 30) { // 垂直堆疊元素，並設置間距
                Image("LogoFridgeChef")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 100) // 調整 Logo 大小
                    .padding(.top, 20)
                    .padding(.bottom, 5)
                
                // 標題
                Text("Reset Password 🗝️")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(
                        Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                
                // Email TextField
                TextField("Enter your Email", text: $email)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal, 20)
                
                // 密碼重設按鈕
                Button(action: {
                    if email.isEmpty {
                        alertMessage = "Enter your Email"
                        showingAlert = true
                    } else {
                        viewModel.sendPasswordReset(email: email)
                        alertMessage = "Send the reset password link to your Email."
                        showingAlert = true
                    }
                }) {
                    Text("Send reset Email link")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 20) // 按鈕的左右內邊距，確保與輸入框對齊
                
                Spacer() // 占位符，將按鈕推到中間位置
                
                Image("monster")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 400, height: 400)
                    .padding(.top)
                
                // 彈出提示框
                    .alert(isPresented: $showingAlert) {
                        Alert(
                            title: Text("Reset Password"),
                            message: Text(alertMessage),
                            dismissButton: .default(Text("Sure"))
                        )
                    }
            }
            .padding(.top, 200) // 將堆疊的元素下移
        }
    }
}


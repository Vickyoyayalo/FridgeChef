//
//  LoginDetailView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//
import SwiftUI

struct LoginDetailView: View {
    @StateObject private var viewModel = LoginDetailViewModel() // 使用 ViewModel
    
    var body: some View {
        
        ZStack {
            
//            Image("LoginDetailPic")
//                .resizable()
//                .overlay(Color.white.opacity(0.3))
//                .ignoresSafeArea()
            
            VStack {
                // Logo 圖片
                Image("LogoFridgeChef")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 200) // 根據實際尺寸調整
                    .padding(.top, 20)
        
                // Email TextField
                TextField("Email", text: $viewModel.email)
                    .padding()
                //                    .background(Color.gray.opacity(0.8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 2))
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                // Password TextField
                SecureField("Password", text: $viewModel.password)
                    .padding()
                //                    .background(Color.gray.opacity(0.8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 2))
                
                // Login Button
                Button(action: {
                    viewModel.login()
                }) 
                {
                    Text("登入")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                // Forgot Password Button
                Button(action: {
                    // 忘記密碼邏輯
                }) 
                {
                    Text("忘記密碼")
                        .foregroundColor(Color.orange)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange, lineWidth: 2))
                }
                Text("Or sign up with")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Google and Facebook buttons
                HStack(spacing: 20) {
                    Button(action: {
                        // Google 登入邏輯
                    }) {
                        HStack {
                            Image(systemName: "g.circle")
                            Text("Google")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        // Facebook 登入邏輯
                    }) {
                        HStack {
                            Image(systemName: "f.circle")
                            Text("Facebook")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("", displayMode: .inline) // 返回按鈕
        }
    }
}

//import SwiftUI
//import FirebaseAuth
//
//struct LoginDetailView: View {
//    @State private var email: String = ""
//    @State private var password: String = ""
//    @State private var errorMessage: String?
//
//    var body: some View {
//        ZStack {
////            Image("LoginDetailImage")
////                .resizable()
////                .overlay(Color.gray.opacity(0.5))
////                .ignoresSafeArea()
//
//            VStack(spacing: 20) {
//                Spacer()
//
//                // Email TextField
//                TextField("Email", text: $email)
//                    .padding()
//                    .background(Color.gray.opacity(0.2))
//                    .cornerRadius(8)
//                    .autocapitalization(.none)
//                    .keyboardType(.emailAddress)
//
//                // Password TextField
//                SecureField("Password", text: $password)
//                    .padding()
//                    .background(Color.gray.opacity(0.2))
//                    .cornerRadius(8)
//
//                // Login Button
//                Button(action: {
//                    // 登入邏輯
//                    login()
//                }) {
//                    Text("登入")
//                        .foregroundColor(.white)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color.orange)
//                        .cornerRadius(8)
//                }
//
//                // Forgot Password Button
//                Button(action: {
//                    // 忘記密碼邏輯
//                }) {
//                    Text("忘記密碼")
//                        .foregroundColor(Color.orange)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange, lineWidth: 2))
//                }
//
//                // Or sign up with (分隔線)
//                Text("Or sign up with")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//
//                // Google and Facebook buttons
//                HStack(spacing: 20) {
//                    Button(action: {
//                        // Google 登入邏輯
//                    }) {
//                        HStack {
//                            Image(systemName: "g.circle")
//                            Text("Google")
//                        }
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.red)
//                        .cornerRadius(8)
//                    }
//
//                    Button(action: {
//                        // Facebook 登入邏輯
//                    }) {
//                        HStack {
//                            Image(systemName: "f.circle")
//                            Text("Facebook")
//                        }
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.blue)
//                        .cornerRadius(8)
//                    }
//                }
//
//                Spacer()
//            }
//            .padding()
//            .navigationBarTitle("", displayMode: .inline) // 返回按鈕
//        }
//    }
//
//    private func login() {
//            // 確認 Email 和 Password 不為空
//            guard !email.isEmpty, !password.isEmpty else {
//                errorMessage = "請輸入電子郵件和密碼。"
//                return
//            }
//
//            // 使用 Firebase 進行登入
//            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
//                if let error = error {
//                    // 如果登入失敗，顯示錯誤訊息
//                    errorMessage = error.localizedDescription
//                } else {
//                    // 登入成功，處理成功邏輯
//                    errorMessage = nil
//                    print("登入成功！")
//                    // 例如跳轉到主頁面邏輯等
//                }
//            }
//        }
//    }
//

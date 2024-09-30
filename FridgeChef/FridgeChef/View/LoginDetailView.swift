//
//  LoginDetailView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//
import SwiftUI

struct LoginDetailView: View {
    
    @StateObject private var loginViewModel = LoginDetailViewModel() // 管理登入相關操作
    @StateObject private var userViewModel = UserViewModel() // 管理跨視圖的用戶數據
    @State private var navigateToHome = false
    @State private var navigateToForgotPassword = false
    @State private var isLoggedIn = false
    
    var body: some View {
        CustomNavigationBarView(title: "") { // 确保有 NavigationView
            ZStack {
                VStack(spacing: 20) {
                    // Logo 圖片
                    Image("LogoFridgeChef")
                        .resizable()
                        .scaledToFit()
                        .padding(.top, 20)
                    
                    // Email TextField
                    TextField("Email", text: $loginViewModel.email)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .shadow(radius: 5)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    // Password SecureField
                    SecureField("Password", text: $loginViewModel.password)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .shadow(radius: 5) // 增加陰影效果
                    
                    // 登入按鈕
                    Button(action: {
                        self.isLoggedIn = true
                        //                         loginViewModel.login {
                        //                             navigateToHome = true  // 成功登入後觸發導航
                        //                         }
                    }) {
                        Text("登入")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                            .cornerRadius(8)
                            .shadow(radius: 5)
                    }
                    
                    // 忘記密碼按鈕
                    Button(action: {
                        print("忘记密码按钮被点击")
                                           navigateToForgotPassword = true
                    }) {
                        Text("忘記密碼?")
                            .foregroundColor(
                                Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                            .frame(maxWidth: .infinity)
                            .fontWeight(.bold)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                                Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange), lineWidth: 2))
                            .shadow(radius: 5)
                    }
//                    .padding(.horizontal, 30)
                    .sheet(isPresented: $navigateToForgotPassword) {
                        ForgotPasswordView()
                    }
                    
                    // 分隔线
                    Text("Or sign up with")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                    
                    // 社交登录按钮
                    HStack(spacing: 20) {
                        SocialLoginButton(imageName: "applelogo", title: "Apple", backgroundColor: Color.black) {
                            // Apple 登录逻辑
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .alert(isPresented: $loginViewModel.showAlert) {
            Alert(title: Text("Error"), message: Text(loginViewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

struct SocialLoginButton: View {
    let imageName: String
    let title: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)
                Text(title)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .cornerRadius(10)
            .shadow(radius: 5)
        }
    }
}

//import SwiftUI
//
//struct LoginDetailView: View {
//    
//    @StateObject private var loginViewModel = LoginDetailViewModel() // 管理登入相關操作
//    @StateObject private var userViewModel = UserViewModel() // 管理跨視圖的用戶數據
//    @State private var navigateToHome = false
//    @State private var navigateToForgotPassword = false
//    @State private var isLoggedIn = false
//    
//    var body: some View {
//        CustomNavigationBarView(title: "") { // 確保有 NavigationView
//            ZStack {
//                VStack(spacing: 20) {
//                    // Logo 圖片
//                    Image("LogoFridgeChef")
//                        .resizable()
//                        .scaledToFit()
//                        .padding(.top, 20)
//                    
//                    // Email TextField
//                    TextField("Email", text: $loginViewModel.email)
//                        .padding()
//                        .background(Color(UIColor.systemGray6))
//                        .cornerRadius(8)
//                        .shadow(radius: 5)
//                        .autocapitalization(.none)
//                        .keyboardType(.emailAddress)
//                    
//                    // Password SecureField
//                    SecureField("Password", text: $loginViewModel.password)
//                        .padding()
//                        .background(Color(UIColor.systemGray6))
//                        .cornerRadius(8)
//                        .shadow(radius: 5) // 增加陰影效果
//                    
//                    // 登入按鈕
//                    Button(action: {
//                        self.isLoggedIn = true
//                        //                         loginViewModel.login {
//                        //                             navigateToHome = true  // 成功登入後觸發導航
//                        //                         }
//                    }) {
//                        Text("登入")
//                            .foregroundColor(.white)
//                            .fontWeight(.bold)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(
//                                Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                            .cornerRadius(8)
//                            .shadow(radius: 5)
//                    }
//                    
//                    // 忘記密碼按鈕
//                    Button(action: {
//                        print("忘记密码按钮被点击")
//                                           navigateToForgotPassword = true
//                    }) {
//                        Text("忘記密碼?")
//                            .foregroundColor(
//                                Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                            .frame(maxWidth: .infinity)
//                            .fontWeight(.bold)
//                            .padding()
//                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(
//                                Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange), lineWidth: 2))
//                            .shadow(radius: 5)
//                    }
//                    .sheet(isPresented: $navigateToForgotPassword) {
//                               ForgotPasswordView()
//                    
//                    // 分隔線
//                    Text("Or sign up with")
//                        .font(.subheadline)
//                        .foregroundColor(.gray)
//                    
//                    // 社交登入按鈕
//                    HStack(spacing: 20) {
//                        //                        SocialLoginButton(imageName: "google_icon", title: "Google", backgroundColor: Color(red: 66/255, green: 133/255, blue: 244/255)) {
//                        //                            // Google 登入邏輯
//                        //                        }
//                        //
//                        //                        SocialLoginButton(imageName: "facebook_icon", title: "Facebook", backgroundColor: Color(red: 59/255, green: 89/255, blue: 152/255)) {
//                        //                            // Facebook 登入邏輯
//                        //                        }
//                        
//                        SocialLoginButton(imageName: "applelogo", title: "Apple", backgroundColor: Color.black) {
//                            // Apple 登入邏輯
//                        }
//                    }
//                    
//                    Spacer()
//                }
//                .padding()
//                }
//            }
//        }
//        .alert(isPresented: $loginViewModel.showAlert) {
//            Alert(title: Text("Error"), message: Text(loginViewModel.alertMessage), dismissButton: .default(Text("OK")))
//        }
//    }
//}
//
//struct SocialLoginButton: View {
//    let imageName: String
//    let title: String
//    let backgroundColor: Color
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            HStack {
//                // 使用 SF Symbol 的圖標
//                Image(systemName: imageName)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 20, height: 20)
//                    .foregroundColor(.white) // 設置圖標為白色
//                Text(title)
//                    .foregroundColor(.white)
//                    .fontWeight(.medium)
//            }
//            .frame(maxWidth: .infinity)
//            .padding()
//            .background(backgroundColor)
//            .cornerRadius(8)
//        }
//    }
//}

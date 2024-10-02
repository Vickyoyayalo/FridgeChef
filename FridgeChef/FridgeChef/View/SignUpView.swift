//
//  SignUpView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//
import SwiftUI

struct SignUpView: View {
    @ObservedObject private var viewModel = UserViewModel()
    @State private var isShowingImagePicker = false

    var body: some View {
        CustomNavigationBarView(title: "") {
            VStack(spacing: 10) { // 調整垂直間距
                // App Logo
                Image("LogoFridgeChef")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 100) // 調整 Logo 大小
                    .padding(.top, 20)
                    .padding(.bottom, 5)

                // User Avatar Button
                Button(action: {
                    self.isShowingImagePicker = true
                }) {
                    if let image = viewModel.avatar {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.orange, lineWidth: 4)) // 添加橙色邊框
                            .shadow(radius: 5) // 添加陰影
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.yellow.opacity(0.2))
                                .frame(width: 150, height: 150)
                            Image("monster")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .padding(.top, 20)
                        }
                    }
                }

                // Name Field
                CustomTextField(placeholder: "姓名", text: $viewModel.name)

                // Email Field
                CustomTextField(placeholder: "Email", text: $viewModel.email, keyboardType: .emailAddress)

                // Password Field
                SecureField("密碼", text: $viewModel.password)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1.5))

                // Sign Up Button
                Button(action: {
                    viewModel.signUpUser()
                }) {
                    Text("註冊")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                               Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                        .cornerRadius(12)
                        .shadow(radius: 5) // 增加陰影效果
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding()
//            .background(Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)) // 背景顏色
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(image: self.$viewModel.avatar)
        }
        .alert(isPresented: $viewModel.showAlert) {
            viewModel.alert
        }
    }
}

// 自定義 TextField
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1.5))
            .keyboardType(keyboardType)
    }
}

#Preview {
    SignUpView()
}

//import SwiftUI
//
//struct SignUpView: View {
//    @ObservedObject private var viewModel = UserViewModel()
//    @State private var isShowingImagePicker = false
//
//    var body: some View {
//        CustomNavigationBarView(title:"") {
//            VStack {
//                Image("LogoFridgeChef")
//                    .resizable()
//                    .scaledToFit()
//                //                .frame(width: 350, height: 200)
//                    .padding(.top, 20)
//                
//                Button(action: {
//                    self.isShowingImagePicker = true
//                }) 
//                {
//                    if let image = viewModel.avatar {
//                        Image(uiImage: image)
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 150, height: 150)
//                            .clipShape(Circle())
//                    } else {
//                        Image(systemName: "person.crop.circle.badge.plus")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 100, height: 100)
//                            .foregroundColor(.orange)
//                    }
//                }
//                
//                TextField("姓名", text: $viewModel.name)
//                    .padding()
//                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 2))
//                
//                TextField("Email", text: $viewModel.email)
//                    .padding()
//                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 2))
//                
//                SecureField("密碼", text: $viewModel.password)
//                    .padding()
//                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 2))
//                
//                Button("註冊") {
//                    viewModel.signUpUser()
//                }
//                .foregroundColor(.white)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(Color.orange)
//                .cornerRadius(8)
//                .padding()
//                
//                Spacer()
//            }
//        }
//        .padding()
//        .sheet(isPresented: $isShowingImagePicker) {
//            ImagePicker(image: self.$viewModel.avatar)
//        }
//        .alert(isPresented: $viewModel.showAlert) {
//            viewModel.alert
//        }
//    }
//}
//
//#Preview {
//    SignUpView()
//}

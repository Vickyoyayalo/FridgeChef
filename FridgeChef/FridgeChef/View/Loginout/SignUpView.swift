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
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        CustomNavigationBarView(title: "") {
            VStack(spacing: 10) {
                
                Image("FridgeChefLogo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 100)
                    .padding(.top, 20)
                    .padding(.bottom, 5)
                
                Button(action: {
                    self.isShowingImagePicker = true
                }, label: {
                    if let image = viewModel.avatar {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.orange, lineWidth: 4))
                            .shadow(radius: 5)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.yellow.opacity(0.2))
                                .frame(width: 150, height: 150)
                            Image("monster")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 200)
                                .padding(.top, 20)
                        }
                    }
                })
                
                CustomTextField(placeholder: "Name", text: $viewModel.name)
                
                CustomTextField(placeholder: "Email", text: $viewModel.email, keyboardType: .emailAddress)
                
                SecureField("Password", text: $viewModel.password)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1.5))
                
                Button(action: {
                    viewModel.signUpUser()
                }, label: {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                })
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(image: self.$viewModel.avatar, sourceType: .photoLibrary)
        }
        .alert(isPresented: $viewModel.showAlert) {
            viewModel.alert
        }
        .onChange(of: viewModel.isSignUpSuccessful) { newValue, _ in
            if newValue {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

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

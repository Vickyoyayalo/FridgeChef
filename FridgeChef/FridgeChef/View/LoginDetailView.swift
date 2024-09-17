//
//  LoginDetailView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import SwiftUI

struct LoginDetailView: View {
    @StateObject private var viewModel = LoginDetailViewModel()
    @State private var navigateToHome = false
    @State private var navigateToForgotPassword = false
    
    var body: some View {
        NavigationView {
            VStack {
                Image("LogoFridgeChef")
                    .resizable()
                    .scaledToFit()
    //                .frame(width: 350, height: 200)
                    .padding(.top, 20)
                    
                TextField("Email", text: $viewModel.email)
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 2))
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $viewModel.password)
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 2))
                
                Button("登入") {
                    viewModel.login {
                        navigateToHome = true  // Trigger navigation on successful login
                    }
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange)
                .cornerRadius(8)
                
                
                Button("忘記密碼?") {
                    navigateToForgotPassword = true
                }
                .foregroundColor(Color.orange)
                .padding()
                .frame(maxWidth: .infinity)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange, lineWidth: 2))
                
                Text("Or sign up with")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
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
                        
                        
                        NavigationLink(destination: HomeView(viewModel: UserViewModel()), isActive: $navigateToHome) { EmptyView() }
                        NavigationLink(destination: ForgotPasswordView(), isActive: $navigateToForgotPassword) { EmptyView() }
                    }
                }
                Spacer()
            }
            
        }
        .padding()
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Error"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}


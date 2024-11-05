//
//  ForgotPasswordView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @ObservedObject private var viewModel = UserViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        CustomNavigationBarView(title: "") {
            
            VStack(spacing: 25) {
                Image("FridgeChefLogo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .padding(.top, 5)
                    .padding(.bottom)
             
                Text("Reset Password 🗝️")
                    .font(.custom("ArialRoundedMTBold", size: 30))
                    .foregroundColor(
                        Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                
                TextField("Enter your Email", text: $email)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                
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
                        .font(.custom("ArialRoundedMTBold", size: 20))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Image("monster")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 400, height: 400)
                    .padding(.top)
                    .alert(isPresented: $showingAlert) {
                        Alert(
                            title: Text("Reset Password"),
                            message: Text(alertMessage),
                            dismissButton: .default(Text("Sure"))
                        )
                    }
            }
            .padding(.top, 100)
        }
    }
}


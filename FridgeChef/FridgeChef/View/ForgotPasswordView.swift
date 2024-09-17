//
//  ForgotPasswordView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/17.
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel = UserViewModel()
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Reset Password") {
                viewModel.sendPasswordReset(email: email) { success in
                    if success {
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        print("Error sending reset password email")
                    }
                }
            }
            .padding()
        }
        .navigationBarTitle("Forgot Password", displayMode: .inline)
        .padding()
    }
}

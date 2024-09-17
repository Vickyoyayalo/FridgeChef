//
//  ForgotPasswordView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/17.
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var showingAlert = false // State to manage alert visibility
    @State private var alertMessage = "" // State to hold the alert message
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel = UserViewModel()  // Ensuring ViewModel is initialized correctly
    
    var body: some View {
            VStack {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                Button("密碼重設") {
                    viewModel.sendPasswordReset(email: email)
                }
                
                .padding()
                .alert(isPresented: $showingAlert) {  // Utilizing local state for alert
                    Alert(
                        title: Text("密碼重設"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("確定"))
                    )
            }
            .navigationBarTitle("Forgot Password", displayMode: .inline)
            .padding()
        }
    }
}


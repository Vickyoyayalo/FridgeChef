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
        VStack {
            Image("LogoFridgeChef")
                .resizable()
                .scaledToFit()
                .frame(width: 350, height: 200)
                .padding(.top, 20)
            
            Button(action: {
                self.isShowingImagePicker = true
            }) {
                if let image = viewModel.avatar {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.orange)
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            TextField("姓名", text: $viewModel.name)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 2))
            
            TextField("Email", text: $viewModel.email)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 2))
            
            SecureField("密碼", text: $viewModel.password)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 2))
            
            Button("註冊") {
                viewModel.signUpUser() { success in
                    if success {
                        print("註冊成功！")
                    } else {
                        print("註冊失败")
                    }
                }
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange)
            .cornerRadius(8)
            .padding()
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(image: self.$viewModel.avatar)
        }
    }
}

#Preview {
    SignUpView()
}

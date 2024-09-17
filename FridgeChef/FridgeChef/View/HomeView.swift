//
//  HomeView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/17.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject private var viewModel: UserViewModel

    var body: some View {
        VStack {
            if let user = viewModel.user {
                Text("Welcome, \(user.name)")
                Text("Email: \(user.email)")
                
                // Using nil-coalescing to provide a default or using a placeholder
                if let avatarURL = user.avatar, let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        Color.gray  // Placeholder if image fails to load
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle")  // Default placeholder image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                }
            }
            
            Button("Logout") {
                viewModel.signOut()
            }
        }
    }
}

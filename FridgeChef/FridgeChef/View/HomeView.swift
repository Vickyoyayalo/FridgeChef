//
//  HomeView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/17.
//

import SwiftUI
import Firebase

struct HomeView: View {
    var uid: String // UID passed from the login process
    
    @State private var user: User? // State to hold the user's data
    
    var body: some View {
        VStack {
            if let user = user {
                VStack(alignment: .center, spacing: 10) {
                    if let avatarURL = user.avatar, let url = URL(string: avatarURL) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable()
                            } else if phase.error != nil {
                                Image(systemName: "person.crop.circle.fill").resizable()
                            } else {
                                ProgressView()
                            }
                        }
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                    }
                    
                    Text(user.name)
                        .font(.title)
                    Text(user.email)
                        .font(.subheadline)
                }
            } else {
                Text("Loading user information...")
            }
            
            Spacer()
            Button("Logout") {
                // Handle logout functionality
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .padding()
        .navigationBarTitle("Profile", displayMode: .inline)
        .onAppear {
            fetchUserData()
        }
    }
    
    // Fetch user data from Firestore
    private func fetchUserData() {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                self.user = try? document.data(as: User.self)
            } else {
                print("Document does not exist or failed to decode: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

#Preview {
    HomeView(uid: "12345")
}

//import SwiftUI
//import FirebaseAuth
//import Kingfisher
//
//struct HomeView: View {
//    @ObservedObject var viewModel: UserViewModel
//
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 20) {
//                if let user = viewModel.user {
//                    Text("Welcome, \(user.name)")
//                    Text("Email: \(user.email)")
//
//                    if let avatarURL = URL(string: user.avatar ?? "") {
//                        KFImage(avatarURL)
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 100, height: 100)
//                            .clipShape(Circle())
//                    } else {
//                        Image(systemName: "person.crop.circle.fill")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 100, height: 100)
//                            .clipShape(Circle())
//                            .foregroundColor(.gray)
//                    }
//                } else {
//                    Text("No user data available.")
//                }
//
//                Button("Logout") {
//                    viewModel.signOut()
//                }
//                .padding()
//                .background(Color.blue)
//                .foregroundColor(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 10))
//            }
//            .padding()
//            .navigationBarTitle("Profile", displayMode: .inline)
//            .onAppear {
//                viewModel.checkForAuthenticatedUser()
//            }
//        }
//    }
//}



//import SwiftUI
//
//struct HomeView: View {
//    @ObservedObject var viewModel: UserViewModel
//
//    var body: some View {
//        VStack {
//            if let user = viewModel.user {
//                Text("Welcome, \(user.name)")
//                Text("Email: \(user.email)")
//
//                if let avatarURL = user.avatar, let url = URL(string: avatarURL) {
//                    AsyncImage(url: url) { image in
//                        image.resizable()
//                    } placeholder: {
//                        Color.gray
//                    }
//                    .frame(width: 100, height: 100)
//                    .clipShape(Circle())
//                } else {
//                    Image(systemName: "person.crop.circle")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 100, height: 100)
//                        .clipShape(Circle())
//                        .foregroundColor(.gray)
//                }
//            } else {
//                Text("No user data available.")
//            }
//
//            Button("Logout") {
//                viewModel.signOut()
//            }
//        }
//    }
//}

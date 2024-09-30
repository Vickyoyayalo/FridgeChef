//
//  MainCollectionView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/30.
//

import SwiftUI
import FirebaseAuth

struct MainCollectionView: View {
    // User Log Status
    @AppStorage("log_Status") private var logStatus: Bool = false
    @State private var showingLogoutConfirmation = false
    
    var body: some View {
        NavigationStack {
            Text("Your content goes here...")
                .padding()
                .navigationTitle("My Collection 🥘")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        logoutButton
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        editButton
                    }
                }
                .alert("Are you sure you want to log out?", isPresented: $showingLogoutConfirmation) {
                    Button("Log Out", role: .destructive) {
                        logOut()
                    }
                    Button("Cancel", role: .cancel) {}
                }
        }
    }

    private var logoutButton: some View {
        Button(action: {
            showingLogoutConfirmation = true
        }) {
            Image(systemName: "power.circle.fill")
        }
    }
    
    private var editButton: some View {
        Button(action: {
            // Perform edit actions here
        }) {
            Image(systemName: "pencil.circle.fill")
        }
    }

    private func logOut() {
        try? Auth.auth().signOut()
        logStatus = false
    }
}

struct MainCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        MainCollectionView()
    }
}

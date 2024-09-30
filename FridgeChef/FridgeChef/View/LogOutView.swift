//
//  LogOutView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/30.
//

import SwiftUI
import FirebaseAuth

struct LogOutView: View {
    //User Log Status
    @AppStorage("log_Status") private var logStatus: Bool = false
    
    var body: some View {
        NavigationStack {
            Button("LogOut") {
                try? Auth.auth().signOut()
                logStatus = false
            }
            .navigationTitle("LogOutView")
        }
    }
}


#Preview {
    LogOutView()
}

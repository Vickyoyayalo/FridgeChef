//
//  ContentView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/30.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("log_Status") private var logStatus: Bool = false

    var body: some View {
        if logStatus {
            LogOutView()  // 登录成功，显示LogoutView
        } else {
            LoginDetailView()  // 未登录，显示LoginDetailView
        }
    }
}

#Preview {
    ContentView()
}

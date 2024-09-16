//
//  FridgeView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import SwiftUI

struct FridgeView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to FridgeChef")
                
                // 這裡可以加入一些導航按鈕
                NavigationLink(destination: SignUpView()) {
                    Text("註冊")
                }
                
                NavigationLink(destination: IngredientView()) {
                    Text("新增食材")
                }
            }
            .navigationTitle("FridgeChef")
        }
    }
}

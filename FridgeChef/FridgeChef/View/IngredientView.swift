//
//  IngredientView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import SwiftUI

struct IngredientView: View {
    @StateObject private var viewModel = IngredientViewModel()
    @State private var name = ""
    @State private var expirationDate = Date()
    @State private var ingredientPhoto: UIImage? = nil // 使用者上傳的照片
    
    var body: some View {
        VStack {
            // 顯示錯誤信息（如果有）
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }
            
            // 食材名稱輸入框
            TextField("食材名稱", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // 有效日期選擇器
            DatePicker("有效期", selection: $expirationDate, displayedComponents: .date)
            
            // 新增食材按鈕
            Button(action: {
                viewModel.addIngredient(name: name, expirationDate: expirationDate, ingredientPhoto: ingredientPhoto) { success in
                    if success {
                        print("食材已新增")
                    } else {
                        print("新增食材失敗")
                    }
                }
            }) {
                Text("新增食材")
            }
            .padding()
        }
        .padding()
    }
}

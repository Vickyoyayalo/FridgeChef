//
//  FridgeView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import SwiftUI

struct FridgeView: View {
    @ObservedObject var viewModel = FridgeViewModel()
    
    var body: some View {
        List(viewModel.ingredients) { ingredient in
            HStack {
                Text(ingredient.name)
                Spacer()
                Text("\(ingredient.quantity)個")
                Text(ingredient.expirationDate, style: .date)
                    .foregroundColor(ingredient.expirationDate <= Date() ? .red : .black)
            }
        }
        .onAppear {
            viewModel.loadIngredients()
        }
        .navigationTitle("我的冰箱")
    }
}


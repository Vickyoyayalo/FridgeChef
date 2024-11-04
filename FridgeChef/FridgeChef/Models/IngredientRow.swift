//
//  IngredientRow.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/2.
//

import SwiftUI
import Foundation

struct IngredientRow: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var ingredient: ParsedIngredient
    var addAction: (ParsedIngredient) -> Bool
    var isInCart: Bool
    
    var body: some View {
        Button(action: {
            _ = addAction(ingredient)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ingredient.name)
                        .foregroundColor(isInCart ? .gray : Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                        .bold()
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if ingredient.quantity > 0 {
                        Text("Qty: \(ingredient.quantity, specifier: "%.2f") \(ingredient.unit)")
                            .font(.custom("ArialRoundedMTBold", size: 15))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                if isInCart {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "cart.badge.plus.fill")
                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                }
            }
            .padding(.vertical, 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

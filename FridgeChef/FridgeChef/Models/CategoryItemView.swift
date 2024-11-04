//
//  CategoryItemView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/4.
//

import SwiftUI
import Foundation

struct CategoryItemView: View {
    let title: String
    let items: [String]
    let primaryColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.custom("ArialRoundedMTBold", size: 16))
                .foregroundColor(primaryColor)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("\(title):")
                    .font(.custom("ArialRoundedMTBold", size: 16))
                    .foregroundColor(.gray)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(items, id: \.self) { item in
                            TagView(text: item)
                        }
                    }
                }
            }
        }
    }
}
